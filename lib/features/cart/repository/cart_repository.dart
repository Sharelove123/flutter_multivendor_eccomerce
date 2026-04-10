import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../controller/cart_controller.dart';

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepository(ref.read(dioProvider));
});

class CartRepository {
  final Dio _dio;
  CartRepository(this._dio);

  Future<void> checkout(List<CartItem> items, Map<String, dynamic> addressData, String paymentMethod) async {
    // 1. Create Address
    final addressRes = await _dio.post('/api/cart/addresses/', data: addressData);
    final addressId = addressRes.data['id'];

    // 2. Submit Order
    final orderItems = items.map((i) => {
      'product': i.product.id,
      'quantity': i.quantity
    }).toList();

    await _dio.post('/api/cart/createorder/', data: {
      'order_items': orderItems,
      'address': addressId,
      'payment_method': paymentMethod
    });
  }

  Future<List<dynamic>> fetchOrders() async {
    try {
      final response = await _dio.get('/api/cart/listorder/').timeout(
            const Duration(seconds: 15),
          );
      final data = response.data;

      if (data is List<dynamic>) {
        return data;
      }

      if (data is Map<String, dynamic> && data['results'] is List<dynamic>) {
        return data['results'] as List<dynamic>;
      }

      return const [];
    } catch (e) {
      throw Exception('Unable to load orders: $e');
    }
  }
}
