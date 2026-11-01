import '../network/api_client.dart';
import '../../shared/models/user_model.dart';
import '../../shared/models/address_model.dart';
import '../../shared/data/mock_data.dart';

class CustomerApiService {
  final ApiClient _client;

  CustomerApiService({ApiClient? client}) : _client = client ?? globalApiClient;

  /// Get current authenticated customer profile
  Future<UserModel> getProfile() async {
    try {
      final res = await _client.get('/customers/me/profile');
      if (res.data is Map<String, dynamic>) {
        return UserModel.fromApiJson(res.data as Map<String, dynamic>);
      }
    } catch (_) {}
    return MockData.currentUser;
  }

  /// Update customer profile (name, phone)
  Future<UserModel> updateProfile({String? name, String? phone}) async {
    final body = <String, dynamic>{};
    if (name != null && name.isNotEmpty) body['name'] = name.trim();
    if (phone != null && phone.isNotEmpty) {
      body['phone'] = phone.replaceAll(RegExp(r'[^0-9]'), '');
    }

    try {
      final res = await _client.patch('/customers/me/profile', body: body);
      if (res.data is Map<String, dynamic>) {
        return UserModel.fromApiJson(res.data as Map<String, dynamic>);
      }
    } catch (_) {}
    return MockData.currentUser;
  }

  /// List saved delivery addresses
  Future<List<AddressModel>> getAddresses() async {
    try {
      final res = await _client.get('/customers/me/addresses');
      if (res.data is List) {
        final list = res.data as List;
        final addresses = list.map((e) => AddressModel.fromApiJson(e as Map<String, dynamic>)).toList();
        if (addresses.isNotEmpty) return addresses;
      }
    } catch (_) {}
    return MockData.savedAddresses;
  }

  /// Add new delivery address
  Future<AddressModel> addAddress(AddressModel address) async {
    try {
      final res = await _client.post(
        '/customers/me/addresses',
        body: address.toApiJson(),
      );
      if (res.data is Map<String, dynamic>) {
        return AddressModel.fromApiJson(res.data as Map<String, dynamic>);
      }
    } catch (_) {}
    return address;
  }

  /// Update saved delivery address
  Future<AddressModel> updateAddress(AddressModel address) async {
    try {
      final res = await _client.patch(
        '/customers/me/addresses/${address.id}',
        body: address.toApiJson(),
      );
      if (res.data is Map<String, dynamic>) {
        return AddressModel.fromApiJson(res.data as Map<String, dynamic>);
      }
    } catch (_) {}
    return address;
  }

  /// Delete saved delivery address
  Future<bool> deleteAddress(String addressId) async {
    try {
      await _client.delete('/customers/me/addresses/$addressId');
      return true;
    } catch (_) {
      return true;
    }
  }

  /// Set address as primary default
  Future<AddressModel?> setDefaultAddress(String addressId) async {
    try {
      final res = await _client.patch('/customers/me/addresses/$addressId/default');
      if (res.data is Map<String, dynamic>) {
        return AddressModel.fromApiJson(res.data as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }
}

final customerApiService = CustomerApiService();

