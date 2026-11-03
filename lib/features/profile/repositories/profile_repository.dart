import '../../../core/models/user_model.dart';
import '../../../core/models/address_model.dart';
import '../../../core/services/customer_api_service.dart';

abstract class ProfileRepository {
  Future<UserModel> getProfile();
  Future<UserModel> updateProfile({String? name, String? phone});
  Future<List<AddressModel>> getSavedAddresses();
  Future<AddressModel> saveAddress(AddressModel address);
  Future<AddressModel> updateAddress(AddressModel address);
  Future<bool> deleteAddress(String addressId);
  Future<AddressModel?> setDefaultAddress(String addressId);
}

class ProfileRepositoryImpl implements ProfileRepository {
  final CustomerApiService _customerService;

  ProfileRepositoryImpl({CustomerApiService? customerService})
      : _customerService = customerService ?? customerApiService;

  @override
  Future<UserModel> getProfile() async {
    return await _customerService.getProfile();
  }

  @override
  Future<UserModel> updateProfile({String? name, String? phone}) async {
    return await _customerService.updateProfile(name: name, phone: phone);
  }

  @override
  Future<List<AddressModel>> getSavedAddresses() async {
    return await _customerService.getAddresses();
  }

  @override
  Future<AddressModel> saveAddress(AddressModel address) async {
    return await _customerService.addAddress(address);
  }

  @override
  Future<AddressModel> updateAddress(AddressModel address) async {
    return await _customerService.updateAddress(address);
  }

  @override
  Future<bool> deleteAddress(String addressId) async {
    return await _customerService.deleteAddress(addressId);
  }

  @override
  Future<AddressModel?> setDefaultAddress(String addressId) async {
    return await _customerService.setDefaultAddress(addressId);
  }
}

final profileRepository = ProfileRepositoryImpl();
