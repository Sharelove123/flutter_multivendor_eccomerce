import '../core/media_url.dart';

class UserModel {
  final String id;
  final String email;
  final String? name;
  final String? avatarUrl;
  final bool isActive;
  final bool isStaff;
  final bool isSuperuser;
  final DateTime? dateJoined;
  final DateTime? lastLogin;

  UserModel({
    required this.id,
    required this.email,
    this.name,
    this.avatarUrl,
    this.isActive = true,
    this.isStaff = false,
    this.isSuperuser = false,
    this.dateJoined,
    this.lastLogin,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final source = _flattenSource(json);
    final resolvedName = _readName(source);
    final resolvedEmail = _readText(source, const [
          'email',
          'user_email',
          'mail',
          'email_address',
        ]) ??
        '';

    return UserModel(
      id: source['id']?.toString() ?? '',
      email: resolvedEmail,
      name: resolvedName,
      avatarUrl: resolveMediaUrl(
        _readText(source, const [
          'avatar_url',
          'avatar',
          'profile_picture',
          'profile_image',
          'image',
        ]),
      ),
      isActive: source['is_active'] ?? true,
      isStaff: source['is_staff'] ?? false,
      isSuperuser: source['is_superuser'] ?? false,
      dateJoined: source['date_joined'] != null ? DateTime.tryParse(source['date_joined']) : null,
      lastLogin: source['last_login'] != null ? DateTime.tryParse(source['last_login']) : null,
    );
  }

  static Map<String, dynamic> _flattenSource(Map<String, dynamic> json) {
    for (final key in const ['user', 'profile', 'data', 'result']) {
      final nested = json[key];
      if (nested is Map<String, dynamic>) {
        return nested;
      }
      if (nested is Map) {
        return nested.map((key, value) => MapEntry(key.toString(), value));
      }
    }

    return json;
  }

  static String? _readName(Map<String, dynamic> json) {
    final directName = _readText(json, const [
      'name',
      'full_name',
      'display_name',
      'username',
    ]);
    if (directName != null && directName.isNotEmpty) {
      return directName;
    }

    final firstName = _readText(json, const ['first_name']) ?? '';
    final lastName = _readText(json, const ['last_name']) ?? '';
    final fullName = '$firstName $lastName'.trim();
    if (fullName.isNotEmpty) {
      return fullName;
    }

    return null;
  }

  static String? _readText(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }
}
