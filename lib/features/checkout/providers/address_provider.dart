import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fdp/core/models/address_model.dart';
import 'package:fdp/core/services/customer_api_service.dart';
import 'package:fdp/features/auth/providers/auth_provider.dart';

class AddressNotifier extends StateNotifier<List<AddressModel>> {
  final CustomerApiService _apiService;

  AddressNotifier({CustomerApiService? apiService})
    : _apiService = apiService ?? customerApiService,
      super(const []);

  Future<void> loadAddresses() async {
    try {
      state = await _apiService.getAddresses();
    } catch (_) {}
  }

  Future<void> addAddress(AddressModel address) async {
    final saved = await _apiService.addAddress(address);
    state = [...state, saved];
  }

  Future<void> editAddress(AddressModel updatedAddress) async {
    final saved = await _apiService.updateAddress(updatedAddress);
    state = state.map((a) => a.id == saved.id ? saved : a).toList();
  }

  Future<void> deleteAddress(String id) async {
    await _apiService.deleteAddress(id);
    state = state.where((a) => a.id != id).toList();
  }

  Future<void> setDefault(String id) async {
    final saved = await _apiService.setDefaultAddress(id);
    state = state
        .map((a) => a.copyWith(isDefault: a.id == id))
        .map((a) => saved?.id == a.id ? saved! : a)
        .toList();
  }

  void clear() => state = const [];
}

final addressListProvider =
    StateNotifierProvider<AddressNotifier, List<AddressModel>>((ref) {
      final notifier = AddressNotifier();
      void syncSession(AuthState auth) {
        if (auth.status == AuthStatus.authenticated) {
          notifier.loadAddresses();
        } else {
          notifier.clear();
        }
      }

      ref.listen(authProvider, (_, auth) => syncSession(auth));
      syncSession(ref.read(authProvider));
      return notifier;
    });
