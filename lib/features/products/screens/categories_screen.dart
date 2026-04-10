import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../models/product_model.dart';
import '../../cart/controller/cart_controller.dart';
import '../controller/wishlist_controller.dart';
import '../controller/products_controller.dart';
import '../widgets/product_card.dart';

enum _SortOption {
  newest('Newest'),
  priceLowToHigh('Price: Low to high'),
  priceHighToLow('Price: High to low'),
  nameAZ('Name: A-Z');

  const _SortOption(this.label);
  final String label;
}

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({
    super.key,
    required this.selectedCategory,
  });

  final String selectedCategory;

  static const List<String> _preferredOrder = [
    'All',
    'Electronics',
    'Clothing',
    'Home & Kitchen',
  ];

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  final _searchController = TextEditingController();
  _SortOption _sort = _SortOption.newest;
  bool _onlyInStock = false;
  bool _onlyDiscounted = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isCategorySelected(String category) {
    return widget.selectedCategory.toLowerCase() == category.toLowerCase();
  }

  List<String> _buildCategoryList(List<Product> products) {
    final discovered = products
        .map((product) => product.categoryName?.trim())
        .whereType<String>()
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final ordered = <String>[
      ...CategoriesScreen._preferredOrder.where(
        (category) => category == 'All' || discovered.contains(category),
      ),
      ...discovered.where((category) => !CategoriesScreen._preferredOrder.contains(category)),
    ];

    if (!ordered.contains('All')) {
      ordered.insert(0, 'All');
    }

    return ordered;
  }

  List<Product> _applyFilters(List<Product> products) {
    final query = _searchController.text.trim().toLowerCase();

    final filtered = products.where((product) {
      final matchesCategory = _isCategorySelected('All') ||
          (product.categoryName ?? '').toLowerCase() ==
              widget.selectedCategory.toLowerCase();
      final matchesSearch = query.isEmpty ||
          product.title.toLowerCase().contains(query) ||
          (product.vendorName ?? '').toLowerCase().contains(query) ||
          (product.description ?? '').toLowerCase().contains(query);
      final matchesStock = !_onlyInStock || product.stock > 0;
      final matchesDiscount =
          !_onlyDiscounted || product.originalPrice > product.discountedPrice;

      return matchesCategory &&
          matchesSearch &&
          matchesStock &&
          matchesDiscount;
    }).toList();

    switch (_sort) {
      case _SortOption.priceLowToHigh:
        filtered.sort((a, b) => a.discountedPrice.compareTo(b.discountedPrice));
        break;
      case _SortOption.priceHighToLow:
        filtered.sort((a, b) => b.discountedPrice.compareTo(a.discountedPrice));
        break;
      case _SortOption.nameAZ:
        filtered.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case _SortOption.newest:
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final wishlistCount = ref.watch(wishlistProvider).length;
    final cartCount = ref.watch(
      cartProvider.select(
        (items) => items.fold<int>(0, (sum, item) => sum + item.quantity),
      ),
    );
    final productsAsync = _isCategorySelected('All')
        ? ref.watch(productsProvider)
        : ref.watch(productsByCategoryProvider(widget.selectedCategory));

    return Scaffold(
      body: productsAsync.when(
        data: (products) {
          final categories = _buildCategoryList(products);
          final filteredProducts = _applyFilters(products);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                pinned: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => context.pop(),
                ),
                title: Text(
                  'Products',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                actions: [
                  _ToolbarBadgeButton(
                    icon: Icons.favorite_border_rounded,
                    count: wishlistCount,
                    onPressed: () => context.push('/wishlist'),
                  ),
                  _ToolbarBadgeButton(
                    icon: Icons.shopping_cart_outlined,
                    count: cartCount,
                    onPressed: () => context.push('/cart'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.home_outlined),
                    onPressed: () => context.go('/'),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                  child: Text(
                    'Search the catalog, narrow the list, and sort products without leaving the grid.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.mutedTextColor,
                        ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                      hintText: 'Search by product, seller, or keyword',
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 52,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = _isCategorySelected(category);

                      return ChoiceChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (_) => context.go(
                          '/categories?name=${Uri.encodeComponent(category)}',
                        ),
                        selectedColor: AppTheme.primaryColor,
                        labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: isSelected ? Colors.white : AppTheme.primaryColor,
                            ),
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: isSelected ? AppTheme.primaryColor : const Color(0x14000000),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      );
                    },
                    separatorBuilder: (context, index) => const SizedBox(width: 10),
                    itemCount: categories.length,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilterChip(
                        label: const Text('In stock only'),
                        selected: _onlyInStock,
                        onSelected: (value) => setState(() => _onlyInStock = value),
                      ),
                      FilterChip(
                        label: const Text('Discounted only'),
                        selected: _onlyDiscounted,
                        onSelected: (value) =>
                            setState(() => _onlyDiscounted = value),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0x14000000)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<_SortOption>(
                            value: _sort,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _sort = value);
                              }
                            },
                            items: _SortOption.values
                                .map(
                                  (value) => DropdownMenuItem(
                                    value: value,
                                    child: Text(value.label),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _isCategorySelected('All')
                              ? 'All products'
                              : widget.selectedCategory,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      Text(
                        '${filteredProducts.length} items',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              if (filteredProducts.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No products matched the current search and filters.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 260,
                      mainAxisSpacing: 18,
                      crossAxisSpacing: 18,
                      childAspectRatio: 0.68,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => ProductCard(product: filteredProducts[index]),
                      childCount: filteredProducts.length,
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load categories.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
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
