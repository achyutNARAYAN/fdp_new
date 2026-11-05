import '../network/api_client.dart';
import '../constants/api_constants.dart';
import 'package:fdp/core/models/user_model.dart';
import 'package:fdp/core/models/address_model.dart';
import '../errors/api_exception.dart';

class CustomerApiService {
  final ApiClient _client;

  CustomerApiService({ApiClient? client}) : _client = client ?? globalApiClient;

  void _requireSession() {
    if (_client.authToken == null || _client.authToken!.isEmpty) {
      throw ApiException(message: 'Please sign in to manage saved addresses.');
    }
  }

  /// Get current authenticated customer profile
  /// GET /customers/me/profile
  Future<UserModel> getProfile() async {
    final res = await _client.get(ApiConstants.customerProfile);
    if (res.data is Map<String, dynamic>) {
      return UserModel.fromApiJson(res.data as Map<String, dynamic>);
    }
    throw FormatException('Invalid customer profile response');
  }

  /// Update customer profile (name, phone)
  /// PATCH /customers/me/profile
  Future<UserModel> updateProfile({String? name, String? phone}) async {
    final body = <String, dynamic>{};
    if (name != null && name.isNotEmpty) body['name'] = name.trim();
    if (phone != null && phone.isNotEmpty) {
      body['phone'] = phone.replaceAll(RegExp(r'[^0-9]'), '');
    }

    final res = await _client.patch(ApiConstants.customerProfile, body: body);
    if (res.data is Map<String, dynamic>) {
      return UserModel.fromApiJson(res.data as Map<String, dynamic>);
    }
    throw FormatException('Invalid updated profile response');
  }

  /// List saved delivery addresses
  /// GET /customers/me/addresses
  Future<List<AddressModel>> getAddresses() async {
    _requireSession();
    final res = await _client.get(ApiConstants.customerAddresses);
    if (res.data is List) {
      return (res.data as List)
          .map((e) => AddressModel.fromApiJson(e as Map<String, dynamic>))
          .toList();
    }
    throw FormatException('Invalid customer addresses response');
  }

  /// Add new delivery address
  /// POST /customers/me/addresses
  Future<AddressModel> addAddress(AddressModel address) async {
    _requireSession();
    final res = await _client.post(
      ApiConstants.customerAddresses,
      body: address.toApiJson(),
    );
    if (res.data is Map<String, dynamic>) {
      return AddressModel.fromApiJson(res.data as Map<String, dynamic>);
    }
    throw FormatException('Invalid created address response');
  }

  /// Update saved delivery address
  /// PATCH /customers/me/addresses/{addressId}
  Future<AddressModel> updateAddress(AddressModel address) async {
    _requireSession();
    final res = await _client.patch(
      ApiConstants.customerAddress(address.id),
      body: address.toApiJson(),
    );
    if (res.data is Map<String, dynamic>) {
      return AddressModel.fromApiJson(res.data as Map<String, dynamic>);
    }
    throw FormatException('Invalid updated address response');
  }

  /// Delete saved delivery address
  /// DELETE /customers/me/addresses/{addressId}
  Future<bool> deleteAddress(String addressId) async {
    _requireSession();
    await _client.delete(ApiConstants.customerAddress(addressId));
    return true;
  }

  /// Set address as primary default
  /// PATCH /customers/me/addresses/{addressId}/default
  Future<AddressModel?> setDefaultAddress(String addressId) async {
    _requireSession();
    final res = await _client.patch(
      ApiConstants.customerAddressDefault(addressId),
    );
    if (res.data is Map<String, dynamic>) {
      return AddressModel.fromApiJson(res.data as Map<String, dynamic>);
    }
    return null;
  }
}

final customerApiService = CustomerApiService();
