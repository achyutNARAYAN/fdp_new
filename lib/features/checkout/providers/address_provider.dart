import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fdp/core/models/address_model.dart';
import 'package:fdp/core/services/customer_api_service.dart';
import 'package:fdp/core/providers/location_provider.dart';
import 'package:fdp/features/auth/providers/auth_provider.dart';

class AddressNotifier extends StateNotifier<List<AddressModel>> {
  final CustomerApiService _apiService;
  final Ref? _ref;
  int _loadGeneration = 0;

  AddressNotifier({CustomerApiService? apiService, Ref? ref})
    : _apiService = apiService ?? customerApiService,
      _ref = ref,
      super(const []);

  Future<void> loadAddresses() async {
    final generation = ++_loadGeneration;
    try {
      final addresses = await _apiService.getAddresses();
      if (generation != _loadGeneration) return;
      state = addresses;

      if (_ref != null && addresses.isNotEmpty) {
        final currentSelected = _ref.read(locationProvider).selectedAddress;
        if (currentSelected == null) {
          final defaultAddr =
              addresses.where((a) => a.isDefault).firstOrNull ?? addresses.first;
          _ref.read(locationProvider.notifier).selectAddress(defaultAddr);
        }
      }
    } catch (_) {}
  }

  Future<void> addAddress(AddressModel address) async {
    final saved = await _apiService.addAddress(address);
    state = [...state, saved];
    if (_ref != null &&
        (_ref.read(locationProvider).selectedAddress == null || saved.isDefault)) {
      _ref.read(locationProvider.notifier).selectAddress(saved);
    }
  }

  Future<void> editAddress(AddressModel updatedAddress) async {
    final saved = await _apiService.updateAddress(updatedAddress);
    state = state.map((a) => a.id == saved.id ? saved : a).toList();
    if (_ref != null && _ref.read(locationProvider).selectedAddress?.id == saved.id) {
      _ref.read(locationProvider.notifier).selectAddress(saved);
    }
  }

  Future<void> deleteAddress(String id) async {
    await _apiService.deleteAddress(id);
    state = state.where((a) => a.id != id).toList();
    if (_ref != null && _ref.read(locationProvider).selectedAddress?.id == id) {
      final remaining = state.where((a) => a.id != id).toList();
      if (remaining.isNotEmpty) {
        final next = remaining.where((a) => a.isDefault).firstOrNull ?? remaining.first;
        _ref.read(locationProvider.notifier).selectAddress(next);
      }
    }
  }

  Future<void> setDefault(String id) async {
    final saved = await _apiService.setDefaultAddress(id);
    state = state
        .map((a) => a.copyWith(isDefault: a.id == id))
        .map((a) => saved?.id == a.id ? saved! : a)
        .toList();
    if (_ref != null && saved != null) {
      _ref.read(locationProvider.notifier).selectAddress(saved);
    }
  }

  void clear() {
    _loadGeneration++;
    state = const [];
  }
}

final addressListProvider =
    StateNotifierProvider<AddressNotifier, List<AddressModel>>((ref) {
      final notifier = AddressNotifier(ref: ref);
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
