import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/product_model.dart';
import '../controller/wishlist_controller.dart';

class ProductCard extends ConsumerWidget {
  const ProductCard({super.key, required this.product});

  final Product product;

  String _formatPrice(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasDiscount = product.originalPrice > product.discountedPrice;
    final isSaved = ref.watch(wishlistProvider).contains(product.id);

    return GestureDetector(
      onTap: () => context.push('/product', extra: product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0x14000000)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x120F172A),
              blurRadius: 30,
              offset: Offset(0, 18),
            )
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      color: const Color(0xFFF6F1E8),
                      child: product.img1 != null
                          ? CachedNetworkImage(
                              imageUrl: product.img1!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.image_not_supported),
                            )
                          : const Icon(
                              Icons.image_outlined,
                              size: 44,
                              color: Colors.grey,
                            ),
                    ),
                  ),
                  if (product.categoryName != null && product.categoryName!.isNotEmpty)
                    Positioned(
                      left: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          product.categoryName!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF475569),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  if (hasDiscount)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF121A23),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${((1 - (product.discountedPrice / product.originalPrice)) * 100).round()}% off',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    right: hasDiscount ? 12 : 12,
                    top: hasDiscount ? 52 : 12,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () async {
                          await ref.read(wishlistProvider.notifier).toggle(product.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isSaved
                                      ? 'Removed from saved items.'
                                      : 'Added to saved items.',
                                ),
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 20,
                            color: isSaved ? Colors.red : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: theme.textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  if (product.vendorName != null && product.vendorName!.isNotEmpty)
                    Row(
                      children: [
                        const Icon(
                          Icons.storefront,
                          size: 14,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            product.vendorName!,
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  if (product.vendorName != null && product.vendorName!.isNotEmpty)
                    const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${_formatPrice(product.discountedPrice)}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: const Color(0xFF121A23),
                        ),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            '\$${_formatPrice(product.originalPrice)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
