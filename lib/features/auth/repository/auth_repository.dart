import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../core/upload_file_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.read(dioProvider),
    ref.read(sharedPreferencesProvider),
  );
});

class AuthRepository {
  final Dio _dio;
  final SharedPreferences _prefs;
  static const _lastEmailKey = 'last_email';

  AuthRepository(this._dio, this._prefs);

  Future<void> login(String email, String password) async {
    try {
      final response = await _dio.post('/api/auth/login/', data: {
        'email': email,
        'password': password,
      });
      
      final data = response.data;
      if (data['access'] != null) {
        await _prefs.setString('access_token', data['access']);
        if (data['refresh'] != null) {
           await _prefs.setString('refresh_token', data['refresh']);
        }
      }
      await _prefs.setString(_lastEmailKey, email.trim());
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<void> register(
    String name,
    String email,
    String password, {
    UploadFileData? avatar,
  }) async {
    try {
      final payload = <String, dynamic>{
        'name': name,
        'email': email,
        'password1': password,
        'password2': password,
      };

      final avatarFile = await _toMultipartFile(avatar);
      if (avatarFile != null) {
        payload['avatar'] = avatarFile;
      }

      await _dio.post(
        '/api/auth/register/',
        data: FormData.fromMap(payload),
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      await _prefs.setString(_lastEmailKey, email.trim());
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _dio.get('/api/auth/user/').timeout(
            const Duration(seconds: 15),
          );
      final userMap = _extractUserMap(response.data);
      if (userMap == null) {
        throw Exception('Unexpected profile response format');
      }
      final cachedEmail = _prefs.getString(_lastEmailKey);
      if ((userMap['email'] == null || userMap['email'].toString().trim().isEmpty) &&
          cachedEmail != null &&
          cachedEmail.trim().isNotEmpty) {
        userMap['email'] = cachedEmail.trim();
      }
      return UserModel.fromJson(userMap);
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    } catch (e) {
      throw Exception('Unable to load user profile: $e');
    }
  }

  Future<void> updateProfile({
    required String name,
    UploadFileData? avatar,
  }) async {
    try {
      final payload = <String, dynamic>{
        'name': name,
      };

      final avatarFile = await _toMultipartFile(avatar);
      if (avatarFile != null) {
        payload['avatar'] = avatarFile;
      }

      await _dio.post(
        '/api/auth/profile/update/',
        data: FormData.fromMap(payload),
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  String _extractErrorMessage(DioException e) {
    if (e.response != null && e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map && data.isNotEmpty) {
        final firstKey = data.keys.first;
        final firstError = data[firstKey];
        if (firstError is List && firstError.isNotEmpty) {
          return "$firstKey: ${firstError.first.toString()}";
        }
        return "$firstKey: ${firstError.toString()}";
      }
      return data.toString();
    }
    return e.message ?? 'An unknown error occurred';
  }

  Future<void> logout() async {
    await _prefs.remove('access_token');
    await _prefs.remove('refresh_token');
    await _prefs.remove(_lastEmailKey);
    try {
      await _dio.post('/api/auth/logout/');
    } catch (_) {
      // Ignore if server logout fails
    }
  }

  bool get isAuthenticated {
    return _prefs.getString('access_token') != null;
  }

  Future<MultipartFile?> _toMultipartFile(UploadFileData? file) async {
    if (file == null) {
      return null;
    }

    if (file.bytes != null) {
      return MultipartFile.fromBytes(file.bytes!, filename: file.name);
    }

    if (file.path != null && file.path!.trim().isNotEmpty) {
      return MultipartFile.fromFile(file.path!, filename: file.name);
    }

    return null;
  }

  Map<String, dynamic>? _extractUserMap(dynamic data) {
    final map = _asStringKeyedMap(data);
    if (map == null) {
      return null;
    }

    for (final key in const ['user', 'profile', 'data', 'result']) {
      final nested = _asStringKeyedMap(map[key]);
      if (nested != null) {
        return nested;
      }
    }

    return map;
  }

  Map<String, dynamic>? _asStringKeyedMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map(
        (key, val) => MapEntry(key.toString(), val),
      );
    }

    return null;
  }
}
