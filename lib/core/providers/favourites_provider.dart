import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/favourite_entry.dart';
import '../models/product.dart';

class FavouritesState {
  const FavouritesState({this.items = const []});

  final List<FavouriteEntry> items;

  Set<int> get ids => items.map((e) => e.id).toSet();

  bool contains(int productId) => ids.contains(productId);
}

class FavouritesNotifier extends StateNotifier<FavouritesState> {
  FavouritesNotifier() : super(const FavouritesState()) {
    _load();
  }

  static const _storageKey = 'favourite_products_v1';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final items = decoded
          .map((e) => FavouriteEntry.fromJson(e as Map<String, dynamic>))
          .where((e) => e.id > 0)
          .toList();
      state = FavouritesState(items: items);
    } catch (_) {}
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(state.items.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> toggle(Product product) async {
    if (product.id <= 0) return;

    if (state.contains(product.id)) {
      state = FavouritesState(
        items: state.items.where((e) => e.id != product.id).toList(),
      );
    } else {
      state = FavouritesState(
        items: [
          FavouriteEntry.fromProduct(product),
          ...state.items.where((e) => e.id != product.id),
        ],
      );
    }
    await _persist();
  }

  Future<void> remove(int productId) async {
    if (!state.contains(productId)) return;
    state = FavouritesState(
      items: state.items.where((e) => e.id != productId).toList(),
    );
    await _persist();
  }
}

final favouritesProvider =
    StateNotifierProvider<FavouritesNotifier, FavouritesState>((ref) {
  return FavouritesNotifier();
});

final favouriteCountProvider = Provider<int>((ref) {
  return ref.watch(favouritesProvider).items.length;
});

final isProductFavouriteProvider = Provider.family<bool, int>((ref, productId) {
  return ref.watch(favouritesProvider).contains(productId);
});
