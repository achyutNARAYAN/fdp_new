import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/address_model.dart';
import '../data/mock_data.dart';
import '../../core/services/customer_api_service.dart';

class AddressNotifier extends StateNotifier<List<AddressModel>> {
  final CustomerApiService _apiService;

  AddressNotifier({CustomerApiService? apiService})
      : _apiService = apiService ?? customerApiService,
        super(MockData.savedAddresses) {
    loadAddresses();
  }

  Future<void> loadAddresses() async {
    try {
      final addresses = await _apiService.getAddresses();
      if (addresses.isNotEmpty) {
        state = addresses;
      }
    } catch (_) {}
  }

  Future<void> addAddress(AddressModel address) async {
    state = [...state, address];
    try {
      final saved = await _apiService.addAddress(address);
      state = state.map((a) => a.id == address.id ? saved : a).toList();
    } catch (_) {}
  }

  Future<void> editAddress(AddressModel updatedAddress) async {
    state = state.map((a) => a.id == updatedAddress.id ? updatedAddress : a).toList();
    try {
      await _apiService.updateAddress(updatedAddress);
    } catch (_) {}
  }

  Future<void> deleteAddress(String id) async {
    state = state.where((a) => a.id != id).toList();
    try {
      await _apiService.deleteAddress(id);
    } catch (_) {}
  }

  Future<void> setDefault(String id) async {
    state = state.map((a) => a.copyWith(isDefault: a.id == id)).toList();
    try {
      await _apiService.setDefaultAddress(id);
    } catch (_) {}
  }
}

final addressListProvider = StateNotifierProvider<AddressNotifier, List<AddressModel>>((ref) {
  return AddressNotifier();
});
