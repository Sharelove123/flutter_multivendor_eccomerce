import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/upload_file_data.dart';
import '../../../models/user_model.dart';
import '../repository/auth_repository.dart';
import '../../vendor/repository/vendor_repository.dart';

final authStateProvider = NotifierProvider<AuthNotifier, bool>(() {
  return AuthNotifier();
});

final currentUserProvider = FutureProvider<UserModel>((ref) async {
  return ref.read(authRepositoryProvider).getCurrentUser();
});

final profileVendorStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.read(vendorRepositoryProvider).checkStatus();
});

class AuthNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref.read(authRepositoryProvider).isAuthenticated;
  }

  Future<void> login(String email, String password) async {
    await ref.read(authRepositoryProvider).login(email, password);
    ref.invalidate(currentUserProvider);
    ref.invalidate(profileVendorStatusProvider);
    state = true;
  }

  Future<void> register(
    String name,
    String email,
    String password, {
    UploadFileData? avatar,
  }) async {
    await ref
        .read(authRepositoryProvider)
        .register(name, email, password, avatar: avatar);
  }

  Future<void> updateProfile({
    required String name,
    UploadFileData? avatar,
  }) async {
    await ref.read(authRepositoryProvider).updateProfile(
          name: name,
          avatar: avatar,
        );
    ref.invalidate(currentUserProvider);
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    ref.invalidate(currentUserProvider);
    ref.invalidate(profileVendorStatusProvider);
    state = false;
  }
}
