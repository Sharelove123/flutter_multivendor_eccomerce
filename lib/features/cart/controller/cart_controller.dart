import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/product_model.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(() {
  return CartNotifier();
});

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() {
    return [];
  }

  void add(Product product, {int qty = 1}) {
    final stateList = List<CartItem>.from(state);
    final idx = stateList.indexWhere((i) => i.product.id == product.id);
    if (idx >= 0) {
      stateList[idx].quantity += qty;
    } else {
      stateList.add(CartItem(product: product, quantity: qty));
    }
    state = stateList;
  }

  void remove(int productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  void clear() {
    state = [];
  }
  
  double get total => state.fold(0.0, (sum, item) => sum + (item.product.discountedPrice * item.quantity));
}
