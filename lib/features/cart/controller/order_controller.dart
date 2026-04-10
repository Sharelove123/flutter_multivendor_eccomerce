import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/order_model.dart';
import '../repository/cart_repository.dart';

final myOrdersProvider = FutureProvider<List<OrderModel>>((ref) async {
  final rawOrders = await ref.read(cartRepositoryProvider).fetchOrders();
  return rawOrders.map((json) => OrderModel.fromJson(json)).toList();
});
