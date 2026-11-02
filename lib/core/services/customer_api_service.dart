import '../network/api_client.dart';
import '../../shared/models/user_model.dart';
import '../../shared/models/address_model.dart';
import '../network/api_exception.dart';

class CustomerApiService {
  final ApiClient _client;

  CustomerApiService({ApiClient? client}) : _client = client ?? globalApiClient;

  void _requireSession() {
    if (_client.authToken == null || _client.authToken!.isEmpty) {
      throw ApiException(message: 'Please sign in to manage saved addresses.');
    }
  }

  /// Get current authenticated customer profile
  Future<UserModel> getProfile() async {
    final res = await _client.get('/customers/me/profile');
    if (res.data is Map<String, dynamic>) {
      return UserModel.fromApiJson(res.data as Map<String, dynamic>);
    }
    throw FormatException('Invalid customer profile response');
  }

  /// Update customer profile (name, phone)
  Future<UserModel> updateProfile({String? name, String? phone}) async {
    final body = <String, dynamic>{};
    if (name != null && name.isNotEmpty) body['name'] = name.trim();
    if (phone != null && phone.isNotEmpty) {
      body['phone'] = phone.replaceAll(RegExp(r'[^0-9]'), '');
    }

    final res = await _client.patch('/customers/me/profile', body: body);
    if (res.data is Map<String, dynamic>) {
      return UserModel.fromApiJson(res.data as Map<String, dynamic>);
    }
    throw FormatException('Invalid updated profile response');
  }

  /// List saved delivery addresses
  Future<List<AddressModel>> getAddresses() async {
    _requireSession();
    final res = await _client.get('/customers/me/addresses');
    if (res.data is List) {
      return (res.data as List)
          .map((e) => AddressModel.fromApiJson(e as Map<String, dynamic>))
          .toList();
    }
    throw FormatException('Invalid customer addresses response');
  }

  /// Add new delivery address
  Future<AddressModel> addAddress(AddressModel address) async {
    _requireSession();
    final res = await _client.post(
      '/customers/me/addresses',
      body: address.toApiJson(),
    );
    if (res.data is Map<String, dynamic>) {
      return AddressModel.fromApiJson(res.data as Map<String, dynamic>);
    }
    throw FormatException('Invalid created address response');
  }

  /// Update saved delivery address
  Future<AddressModel> updateAddress(AddressModel address) async {
    _requireSession();
    final res = await _client.patch(
      '/customers/me/addresses/${address.id}',
      body: address.toApiJson(),
    );
    if (res.data is Map<String, dynamic>) {
      return AddressModel.fromApiJson(res.data as Map<String, dynamic>);
    }
    throw FormatException('Invalid updated address response');
  }

  /// Delete saved delivery address
  Future<bool> deleteAddress(String addressId) async {
    _requireSession();
    await _client.delete('/customers/me/addresses/$addressId');
    return true;
  }

  /// Set address as primary default
  Future<AddressModel?> setDefaultAddress(String addressId) async {
    _requireSession();
    final res = await _client.patch(
      '/customers/me/addresses/$addressId/default',
    );
    if (res.data is Map<String, dynamic>) {
      return AddressModel.fromApiJson(res.data as Map<String, dynamic>);
    }
    return null;
  }
}

final customerApiService = CustomerApiService();
