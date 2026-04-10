import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/product_model.dart';
import '../../cart/controller/cart_controller.dart';
import '../controller/review_controller.dart';
import '../controller/wishlist_controller.dart';
import '../repository/review_repository.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  final _commentController = TextEditingController();
  int _selectedRating = 5;
  late PageController _imageController;
  int _currentImageIndex = 0;

  void _submitReview() async {
    try {
      await ref.read(reviewRepositoryProvider).submitReview(
        widget.product.id,
        _selectedRating,
        _commentController.text,
      );
      ref.invalidate(productReviewsProvider(widget.product.id));
      _commentController.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review posted!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  void initState() {
    super.initState();
    _imageController = PageController();
  }

  @override
  void dispose() {
    _imageController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reviewsAsync = ref.watch(productReviewsProvider(widget.product.id));
    final product = widget.product;
    final isSaved = ref.watch(wishlistProvider).contains(product.id);

    // Get all available images
    final images = [
      product.img1,
      product.img2,
      product.img3,
      product.img4,
    ].where((img) => img != null).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: images.isEmpty
                  ? Container(color: Colors.grey.withOpacity(0.2), child: const Icon(Icons.image, size: 80))
                  : Stack(
                      children: [
                        PageView.builder(
                          controller: _imageController,
                          onPageChanged: (index) {
                            setState(() => _currentImageIndex = index);
                          },
                          itemCount: images.length,
                          itemBuilder: (context, index) {
                            return CachedNetworkImage(
                              imageUrl: images[index]!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey.withOpacity(0.2),
                                child: const Center(child: CircularProgressIndicator()),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey.withOpacity(0.2),
                                child: const Icon(Icons.image, size: 80),
                              ),
                            );
                          },
                        ),
                        if (images.length > 1)
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                images.length,
                                (index) => Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: index == _currentImageIndex
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.title,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (product.rating != null)
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(product.rating.toString(), style: Theme.of(context).textTheme.titleMedium),
                          ],
                        )
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (product.vendorName != null)
                    Row(
                      children: [
                        const Icon(Icons.storefront, color: Colors.grey, size: 20),
                        const SizedBox(width: 8),
                        Text(product.vendorName!, style: const TextStyle(color: Colors.grey, fontSize: 16)),
                        const Spacer(),
                        IconButton(
                          tooltip: isSaved ? 'Remove from saved' : 'Save item',
                          onPressed: () => ref.read(wishlistProvider.notifier).toggle(product.id),
                          icon: Icon(
                            isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isSaved ? Colors.red : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text(
                        '\$${product.discountedPrice}',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (product.originalPrice > product.discountedPrice)
                        Text(
                          '\$${product.originalPrice}',
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                            fontSize: 20,
                          ),
                        ),
                      if (product.discountPercentage != null && product.discountPercentage! > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${product.discountPercentage}% OFF',
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text('Description', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    product.description ?? 'No description available.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                          color: const Color(0xFF1E293B),
                        ),
                  ),
                  const Divider(height: 48),
                  
                  // Reviews Section
                  Text(
                    'Customer Reviews',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF121A23),
                        ),
                  ),
                  const SizedBox(height: 16),
                  
                  reviewsAsync.when(
                    data: (reviews) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (reviews.isEmpty)
                            Text(
                              'No reviews yet. Be the first!',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF475569),
                                  ),
                            )
                          else
                            ...reviews.map((r) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              color: Colors.white,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFFF4EFE6),
                                  backgroundImage: r.reviewerAvatarUrl != null
                                      ? NetworkImage(r.reviewerAvatarUrl!)
                                      : null,
                                  child: r.reviewerAvatarUrl == null
                                      ? Text(
                                          _reviewerInitial(r.reviewerName),
                                          style: const TextStyle(
                                            color: Color(0xFF121A23),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                title: Row(
                                  children: [
                                    Text(
                                      r.reviewerName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF121A23),
                                      ),
                                    ),
                                    const Spacer(),
                                    const Icon(Icons.star, color: Colors.amber, size: 16),
                                    Text(
                                      '${r.rating}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF121A23),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.comment.isEmpty ? 'No review text provided.' : r.comment,
                                      style: const TextStyle(color: Color(0xFF475569)),
                                    ),
                                    if (r.createdAt != null) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        '${r.createdAt!.toLocal()}'.split('.')[0],
                                        style: const TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            )),
                            const SizedBox(height: 24),
                            // Write Review
                            Text(
                              'Write a Review',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF121A23),
                                  ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButton<int>(
                              value: _selectedRating,
                              items: [1,2,3,4,5].map((e) => DropdownMenuItem(value: e, child: Text('$e Stars'))).toList(),
                              onChanged: (val) => setState(() => _selectedRating = val!),
                            ),
                            TextField(
                              controller: _commentController,
                              decoration: const InputDecoration(labelText: 'Your Comment'),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(onPressed: _submitReview, child: const Text('Submit Review')),
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Text('Error loading reviews: $e'),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          )
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(24),
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Row(
          children: [
            OutlinedButton(
              onPressed: () => context.push('/wishlist'),
              child: const Text('Saved'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(cartProvider.notifier).add(product);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart!')));
                },
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Add to Cart'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _reviewerInitial(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return 'A';
    }
    return trimmed[0].toUpperCase();
  }
}
