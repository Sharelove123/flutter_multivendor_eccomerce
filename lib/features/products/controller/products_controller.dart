import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/product_model.dart';
import '../repository/product_repository.dart';

final productsProvider = FutureProvider<List<Product>>((ref) async {
  final repo = ref.read(productRepositoryProvider);
  return repo.getProducts();
});

final productsByCategoryProvider =
    FutureProvider.family<List<Product>, String>((ref, category) async {
  final products = await ref.watch(productsProvider.future);
  return products
      .where(
        (product) =>
            (product.categoryName ?? '').trim().toLowerCase() ==
            category.trim().toLowerCase(),
      )
      .toList();
});
