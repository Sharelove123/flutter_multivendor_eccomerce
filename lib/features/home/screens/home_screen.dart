import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/controller/auth_controller.dart';
import '../../cart/controller/cart_controller.dart';
import '../../products/controller/products_controller.dart';
import '../../products/controller/wishlist_controller.dart';
import '../../products/widgets/product_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allProductsAsync = ref.watch(productsProvider);
    final isAuthenticated = ref.watch(authStateProvider);
    final wishlistCount = ref.watch(wishlistProvider).length;
    final cartCount = ref.watch(
      cartProvider.select(
        (items) => items.fold<int>(0, (sum, item) => sum + item.quantity),
      ),
    );

    return Scaffold(
      body: allProductsAsync.when(
        data: (products) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(productsProvider);
            ref.invalidate(productsByCategoryProvider('Electronics'));
            ref.invalidate(productsByCategoryProvider('Clothing'));
            ref.invalidate(productsByCategoryProvider('Home & Kitchen'));
            await ref.read(productsProvider.future);
          },
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                floating: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                surfaceTintColor: Colors.transparent,
                titleSpacing: 20,
                title: _BrandLockup(onTap: () => context.go('/')),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.grid_view_rounded),
                    onPressed: () => context.push('/categories?name=All'),
                  ),
                  _ToolbarBadgeButton(
                    icon: Icons.shopping_cart_outlined,
                    count: cartCount,
                    onPressed: () => context.push('/cart'),
                  ),
                  _ToolbarBadgeButton(
                    icon: Icons.favorite_border_rounded,
                    count: wishlistCount,
                    onPressed: () => context.push('/wishlist'),
                  ),
                  IconButton(
                    icon: Icon(
                      isAuthenticated ? Icons.account_circle_outlined : Icons.person_outline,
                    ),
                    onPressed: () => context.push(isAuthenticated ? '/profile' : '/login'),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _HeroSection(productCount: products.length),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                child: _CategorySection(
                  title: 'Latest Electronics',
                  category: 'Electronics',
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
              SliverToBoxAdapter(
                child: _CategorySection(
                  title: 'Trending Clothing',
                  category: 'Clothing',
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
              SliverToBoxAdapter(
                child: _CategorySection(
                  title: 'Home & Kitchen Essentials',
                  category: 'Home & Kitchen',
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 36, 20, 120),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0x22B88347)),
                      borderRadius: BorderRadius.circular(999),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFF8DFAB),
                          Color(0xFFF6EDD6),
                          Color(0xFFF8DFAB),
                        ],
                      ),
                    ),
                    child: Text(
                      'STUDENT PROJECT SHOWCASE. DO NOT USE REAL PAYMENT INFORMATION.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontSize: 11,
                            letterSpacing: 1.8,
                          ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load products: $e',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategorySection extends ConsumerWidget {
  const _CategorySection({
    required this.title,
    required this.category,
  });

  final String title;
  final String category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsByCategoryProvider(category));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              TextButton(
                onPressed: () => context.push(
                  '/categories?name=${Uri.encodeComponent(category)}',
                ),
                child: const Text('See all'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        productsAsync.when(
          data: (products) {
            if (products.isEmpty) {
              return const SizedBox.shrink();
            }

            return SizedBox(
              height: 360,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) => SizedBox(
                  width: 250,
                  child: ProductCard(product: products[index]),
                ),
                separatorBuilder: (context, index) => const SizedBox(width: 18),
                itemCount: products.length,
              ),
            );
          },
          loading: () => const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, st) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF121A23),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Curated goods',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(letterSpacing: 1.0),
                ),
                Text(
                  'ECommerce',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(letterSpacing: 0.8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolbarBadgeButton extends StatelessWidget {
  const _ToolbarBadgeButton({
    required this.icon,
    required this.count,
    required this.onPressed,
  });

  final IconData icon;
  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
        ),
        if (count > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.productCount});

  final int productCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8F5EE), Colors.white],
        ),
        border: Border.all(color: const Color(0x14000000)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 900;
            final primary = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0x14000000)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.storefront_outlined, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'MODERN MARKETPLACE',
                        style: theme.textTheme.labelLarge?.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'A sharper way\nto shop everyday essentials.',
                  style: theme.textTheme.displayMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Explore practical tech, clean wardrobe staples, and home upgrades in one place. No oversized banner, no filler, just a storefront built to get you to the right products faster.',
                  style: theme.textTheme.bodyLarge?.copyWith(color: const Color(0xFF475569)),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => context.push('/categories?name=All'),
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Browse all products'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/categories?name=Electronics'),
                      icon: const Icon(Icons.north_east_rounded),
                      label: const Text('Start with electronics'),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                LayoutBuilder(
                  builder: (context, statConstraints) {
                    final compact = statConstraints.maxWidth < 680;
                    final itemWidth = compact
                        ? statConstraints.maxWidth
                        : (statConstraints.maxWidth - 28) / 3;

                    return Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: [
                        SizedBox(
                          width: itemWidth,
                          child: const _MetricCard(
                            eyebrow: 'Curation',
                            value: '3',
                            description:
                                'Focused collections: electronics, clothing, and home essentials.',
                          ),
                        ),
                        SizedBox(
                          width: itemWidth,
                          child: const _MetricCard(
                            eyebrow: 'Storefront',
                            value: 'Fast',
                            description:
                                'Built around quick scanning, horizontal discovery, and direct category entry points.',
                          ),
                        ),
                        SizedBox(
                          width: itemWidth,
                          child: _MetricCard(
                            eyebrow: 'Current inventory',
                            value: '$productCount',
                            description: 'Products currently visible in the public catalog feed.',
                            inverted: true,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            );

            final secondary = Column(
              children: [
                const _SidePanel(
                  title: 'Daily Edit',
                  heading: 'Built for people who know what they want.',
                  description:
                      'Jump into top categories, compare items quickly, and move from landing page to product grid without a giant promotional image slowing the page down.',
                  dark: true,
                ),
                const SizedBox(height: 14),
                _CategoryPanel(
                  title: 'Clothing',
                  description: 'Refined staples and everyday layers.',
                  backgroundColor: const Color(0xFFF4EFE6),
                  onTap: () => context.push('/categories?name=Clothing'),
                ),
                const SizedBox(height: 14),
                _CategoryPanel(
                  title: 'Home & Kitchen',
                  description: 'Practical upgrades for the spaces you use most.',
                  backgroundColor: const Color(0xFFEEF6F7),
                  onTap: () => context.push('/categories?name=Home%20%26%20Kitchen'),
                ),
              ],
            );

            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  primary,
                  const SizedBox(height: 18),
                  secondary,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: primary),
                const SizedBox(width: 18),
                Expanded(flex: 4, child: secondary),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.eyebrow,
    required this.value,
    required this.description,
    this.inverted = false,
  });

  final String eyebrow;
  final String value;
  final String description;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final foreground = inverted ? Colors.white : const Color(0xFF121A23);
    final muted = inverted ? const Color(0xFFD6DCE3) : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: inverted ? const Color(0xFF121A23) : Colors.white.withOpacity(0.86),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: inverted ? Colors.transparent : const Color(0x14000000)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: muted, fontSize: 11),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: foreground),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: muted),
            softWrap: true,
          ),
        ],
      ),
    );
  }
}

class _SidePanel extends StatelessWidget {
  const _SidePanel({
    required this.title,
    required this.heading,
    required this.description,
    this.dark = false,
  });

  final String title;
  final String heading;
  final String description;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final foreground = dark ? Colors.white : const Color(0xFF121A23);
    final muted = dark ? const Color(0xFFD6DCE3) : const Color(0xFF64748B);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: dark ? Colors.transparent : const Color(0x14000000)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: muted, fontSize: 11),
          ),
          const SizedBox(height: 14),
          Text(
            heading,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: foreground),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}

class _CategoryPanel extends StatelessWidget {
  const _CategoryPanel({
    required this.title,
    required this.description,
    required this.backgroundColor,
    required this.onTap,
  });

  final String title;
  final String description;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0x14000000)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CATEGORY',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: const Color(0xFF64748B),
                          fontSize: 11,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(title, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF475569),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.north_east_rounded, color: Color(0xFF121A23)),
          ],
        ),
      ),
    );
  }
}
