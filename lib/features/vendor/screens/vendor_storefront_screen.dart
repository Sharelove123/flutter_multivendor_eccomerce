import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/vendor_repository.dart';
import '../../../models/product_model.dart';
import '../../../models/vendor_model.dart';
import '../../products/widgets/product_card.dart';
import 'package:cached_network_image/cached_network_image.dart';

final vendorStorefrontProvider = FutureProvider.autoDispose.family<List<Product>, String>((ref, slug) async {
  return ref.read(vendorRepositoryProvider).getVendorStorefrontProducts(slug);
});

class VendorStorefrontScreen extends ConsumerWidget {
  final String slug;
  final VendorModel? vendor; 

  const VendorStorefrontScreen({super.key, required this.slug, this.vendor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(vendorStorefrontProvider(slug));

    return Scaffold(
      appBar: AppBar(
        title: Text(vendor?.storeName ?? 'Vendor Storefront'),
      ),
      body: productsAsync.when(
        data: (products) {
          return CustomScrollView(
            slivers: [
              if (vendor != null)
                SliverToBoxAdapter(
                  child: Container(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (vendor!.storeBanner != null)
                          CachedNetworkImage(
                            imageUrl: vendor!.storeBanner!,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              vendor!.storeLogo != null
                                  ? CircleAvatar(
                                      radius: 40,
                                      backgroundImage: CachedNetworkImageProvider(vendor!.storeLogo!),
                                    )
                                  : const Icon(Icons.store, size: 64, color: Colors.blueAccent),
                              const SizedBox(height: 12),
                              Text(vendor!.storeName, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                              Text('${vendor!.averageRating} ★ (${vendor!.productCount} Products)', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                              const SizedBox(height: 16),
                              if (vendor!.storeDescription != null)
                                Text(vendor!.storeDescription!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                              const SizedBox(height: 16),
                              if (vendor!.phone != null && vendor!.phone!.isNotEmpty)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.phone, size: 16, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Text(vendor!.phone!, style: const TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              if (vendor!.address != null && vendor!.address!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Text(vendor!.address!, style: const TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (products.isEmpty)
                const SliverFillRemaining(child: Center(child: Text('This vendor has no products.')))
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return ProductCard(product: products[index]);
                      },
                      childCount: products.length,
                    ),
                  ),
                )
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Failed: $e')),
      ),
    );
  }
}
