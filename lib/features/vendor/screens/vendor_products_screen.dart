import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/product_model.dart';
import 'vendor_dashboard_screen.dart';
import '../repository/vendor_repository.dart';

final vendorProductsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  return ref.read(vendorRepositoryProvider).getMyProducts();
});

class VendorProductsScreen extends ConsumerWidget {
  const VendorProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(vendorProductsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Manage products'),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/vendor/products/new'),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add product'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: productsAsync.when(
        data: (products) {
          if (products.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 640),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: const Color(0x14000000)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircleAvatar(
                        radius: 34,
                        backgroundColor: Color(0xFFF4EFE6),
                        child: Icon(Icons.inventory_2_outlined, size: 30, color: Color(0xFF121A23)),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Your catalog is empty',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Add your first product to make your storefront useful.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => context.push('/vendor/products/new'),
                        child: const Text('Create first product'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: products.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 360,
              mainAxisSpacing: 18,
              crossAxisSpacing: 18,
              childAspectRatio: 0.92,
            ),
            itemBuilder: (context, index) {
              final product = products[index];
              return _VendorProductCard(product: product);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _VendorProductCard extends ConsumerWidget {
  const _VendorProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x14000000)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF6F1E8),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              alignment: Alignment.center,
              child: product.img1 != null && product.img1!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                      child: Image.network(
                        product.img1!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.image_not_supported_outlined,
                          size: 42,
                        ),
                      ),
                    )
                  : const Icon(Icons.inventory_2_outlined, size: 42, color: Color(0xFF64748B)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.title,
                        style: Theme.of(context).textTheme.titleLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: product.isActive ? const Color(0x1A2F6F4F) : const Color(0x14000000),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        product.isActive ? 'Active' : 'Hidden',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: product.isActive ? const Color(0xFF2F6F4F) : const Color(0xFF475569),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        label: 'Price',
                        value: '\$${product.discountedPrice.toStringAsFixed(2)}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniStat(
                        label: 'Stock',
                        value: '${product.stock}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        context.push(
                          '/vendor/products/${product.id}/edit',
                          extra: product,
                        );
                      },
                      child: const Text('Edit product'),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () async {
                        final shouldDelete = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete product'),
                            content: Text(
                              'Delete "${product.title}" from your catalog?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );

                        if (shouldDelete != true) {
                          return;
                        }

                        try {
                          await ref
                              .read(vendorRepositoryProvider)
                              .deleteProduct(product.id);
                          ref.invalidate(vendorProductsProvider);
                          ref.invalidate(vendorDashboardProvider);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Product deleted successfully.'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Delete failed: $e')),
                            );
                          }
                        }
                      },
                      icon: Icon(
                        Icons.delete_outline_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x14000000)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
