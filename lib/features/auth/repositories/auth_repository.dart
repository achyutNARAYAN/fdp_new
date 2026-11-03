import '../../../core/services/auth_api_service.dart';
import '../../../core/services/customer_api_service.dart';
import '../../../core/models/user_model.dart';

abstract class AuthRepository {
  Future<Map<String, dynamic>> requestOtp(String email);
  Future<OtpVerificationResult> verifyOtp({required String email, required String otp});
  Future<UserModel> getCurrentProfile();
  Future<UserModel> updateProfile({String? name, String? phone});
  Future<void> logout();
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthApiService _authService;
  final CustomerApiService _customerService;

  AuthRepositoryImpl({
    AuthApiService? authService,
    CustomerApiService? customerService,
  })  : _authService = authService ?? authApiService,
        _customerService = customerService ?? customerApiService;

  @override
  Future<Map<String, dynamic>> requestOtp(String email) async {
    return await _authService.requestOtp(email);
  }

  @override
  Future<OtpVerificationResult> verifyOtp({required String email, required String otp}) async {
    return await _authService.verifyOtp(email: email, otp: otp);
  }

  @override
  Future<UserModel> getCurrentProfile() async {
    return await _customerService.getProfile();
  }

  @override
  Future<UserModel> updateProfile({String? name, String? phone}) async {
    return await _customerService.updateProfile(name: name, phone: phone);
  }

  @override
  Future<void> logout() async {
    await _authService.logout();
  }
}

final authRepository = AuthRepositoryImpl();
