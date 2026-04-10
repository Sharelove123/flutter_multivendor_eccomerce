import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../../models/product_model.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.read(publicDioProvider));
});

class ProductRepository {
  final Dio _dio;

  ProductRepository(this._dio);

  Future<List<Product>> getProducts() async {
    final response = await _dio.get('/api/core/category/All/?page=1');
    final payload = response.data;

    if (payload is Map<String, dynamic> && payload['results'] is List) {
      final data = payload['results'] as List<dynamic>;
      return data
          .whereType<Map<String, dynamic>>()
          .map(Product.fromJson)
          .toList();
    }

    if (payload is List) {
      return payload
          .whereType<Map<String, dynamic>>()
          .map(Product.fromJson)
          .toList();
    }

    return const [];
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    final response = await _dio.get(
      '/api/core/category/${Uri.encodeComponent(category)}/?page=1',
    );
    final payload = response.data;

    if (payload is Map<String, dynamic> && payload['results'] is List) {
      final data = payload['results'] as List<dynamic>;
      return data
          .whereType<Map<String, dynamic>>()
          .map(Product.fromJson)
          .toList();
    }

    if (payload is List) {
      return payload
          .whereType<Map<String, dynamic>>()
          .map(Product.fromJson)
          .toList();
    }

    return const [];
  }
}
