import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';

final wishlistProvider =
    NotifierProvider<WishlistNotifier, Set<int>>(WishlistNotifier.new);

class WishlistNotifier extends Notifier<Set<int>> {
  static const _storageKey = 'wishlist_product_ids';

  @override
  Set<int> build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final stored = prefs.getStringList(_storageKey) ?? const <String>[];
    return stored
        .map(int.tryParse)
        .whereType<int>()
        .toSet();
  }

  Future<void> toggle(int productId) async {
    final next = Set<int>.from(state);
    if (!next.add(productId)) {
      next.remove(productId);
    }
    await _persist(next);
    state = next;
  }

  bool contains(int productId) => state.contains(productId);

  Future<void> remove(int productId) async {
    final next = Set<int>.from(state)..remove(productId);
    await _persist(next);
    state = next;
  }

  Future<void> clear() async {
    await _persist(<int>{});
    state = <int>{};
  }

  Future<void> _persist(Set<int> ids) {
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.setStringList(
      _storageKey,
      ids.map((id) => id.toString()).toList(),
    );
  }
}
