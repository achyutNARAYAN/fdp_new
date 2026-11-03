import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../repositories/profile_repository.dart';

final userProfileProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

final savedAddressesFutureProvider = FutureProvider((ref) async {
  return await profileRepository.getSavedAddresses();
});
