import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controller/products_controller.dart';
import '../controller/wishlist_controller.dart';
import '../widgets/product_card.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistIds = ref.watch(wishlistProvider);
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved items'),
        actions: [
          if (wishlistIds.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(wishlistProvider.notifier).clear(),
              child: const Text('Clear all'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: productsAsync.when(
        data: (products) {
          final saved = products
              .where((product) => wishlistIds.contains(product.id))
              .toList();

          if (saved.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No saved items yet. Tap the heart icon on a product to keep it here.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: saved.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 260,
              mainAxisSpacing: 18,
              crossAxisSpacing: 18,
              childAspectRatio: 0.68,
            ),
            itemBuilder: (context, index) => ProductCard(product: saved[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Failed to load saved items: $e')),
      ),
    );
  }
}
