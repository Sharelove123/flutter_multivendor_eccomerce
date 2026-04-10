import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/media_url.dart';
import '../repository/vendor_repository.dart';

final vendorStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.read(vendorRepositoryProvider).checkStatus();
});

final vendorDashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.read(vendorRepositoryProvider).getDashboardMetrics();
});

class VendorDashboardScreen extends ConsumerWidget {
  const VendorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(vendorStatusProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Vendor dashboard')),
      body: statusAsync.when(
        data: (status) {
          final isVendor = status['is_vendor'] == true;
          final isApproved = status['is_approved'] == true;

          if (!isVendor) {
            return _DashboardEmptyState(
              title: 'Start your seller workspace',
              description:
                  'Apply as a vendor to unlock product management, order handling, and your storefront dashboard.',
              primaryLabel: 'Become a seller',
              primaryAction: () => context.push('/vendor/register'),
            );
          }

          if (!isApproved) {
            return _DashboardEmptyState(
              title: 'Your seller application is being reviewed',
              description:
                  'You can return here while approval is pending. Once approved, product and order tools will appear automatically.',
              primaryLabel: 'View application',
              primaryAction: () => context.push('/vendor/register'),
              secondaryLabel: 'Back to home',
              secondaryAction: () => context.go('/'),
              icon: Icons.hourglass_top_rounded,
            );
          }

          return const _VendorActiveDashboardView();
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => _DashboardLoadError(
          message: 'Error: $e',
          onRetry: () => ref.invalidate(vendorStatusProvider),
        ),
      ),
    );
  }
}

class _VendorActiveDashboardView extends ConsumerWidget {
  const _VendorActiveDashboardView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(vendorDashboardProvider);

    return dashAsync.when(
      data: (data) {
        final storeName = (data['store_name'] ?? 'Vendor workspace').toString();
        final storeBanner = resolveMediaUrl(data['store_banner']);
        final storeLogo = resolveMediaUrl(data['store_logo']);
        final stats = [
          _DashboardStat(
            label: 'Total revenue',
            value: '\$${(data['total_revenue'] ?? 0).toString()}',
            icon: Icons.trending_up_rounded,
          ),
          _DashboardStat(
            label: 'Total sales',
            value: '${data['total_sales_count'] ?? 0}',
            icon: Icons.shopping_cart_checkout_rounded,
          ),
          _DashboardStat(
            label: 'Active products',
            value: '${data['product_count'] ?? 0}',
            icon: Icons.inventory_2_rounded,
          ),
          _DashboardStat(
            label: 'Average rating',
            value: data['average_rating'] == null ? 'N/A' : '${data['average_rating']}',
            icon: Icons.star_rounded,
          ),
        ];

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(36),
              ),
              child: Stack(
                children: [
                  if (storeBanner != null && storeBanner.isNotEmpty)
                    Positioned.fill(
                      child: Image.network(
                        storeBanner,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                      ),
                    ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF111827).withValues(alpha: 0.55),
                            const Color(0xFF111827).withValues(alpha: 0.95),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vendor dashboard',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: Colors.white70,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 84,
                              width: 84,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.14),
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: storeLogo != null && storeLogo.isNotEmpty
                                  ? Image.network(
                                      storeLogo,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const Icon(
                                        Icons.storefront_outlined,
                                        color: Colors.white,
                                        size: 34,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.storefront_outlined,
                                      color: Colors.white,
                                      size: 34,
                                    ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    storeName,
                                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                          color: Colors.white,
                                        ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Track performance, manage your catalog, and keep the seller workspace aligned with the Next.js frontend flow.',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Colors.white70,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => context.push('/vendor/products/new'),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Add product'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => context.push('/vendor/products'),
                              icon: const Icon(Icons.inventory_2_outlined),
                              label: const Text('Manage products'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Color(0x40FFFFFF)),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => context.push('/vendor/profile'),
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Edit store'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Color(0x40FFFFFF)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 720;
                final cardWidth = compact
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 16) / 2;

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: stats
                      .map(
                        (stat) => SizedBox(
                          width: cardWidth,
                          child: _StatCard(stat: stat),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 900;
                final actionsPanel = _Panel(
                  title: 'Quick actions',
                  child: Column(
                    children: [
                      _ActionTile(
                        icon: Icons.inventory_2_outlined,
                        title: 'Manage products',
                        subtitle: 'Review your listings and add new inventory.',
                        onTap: () => context.push('/vendor/products'),
                      ),
                      _ActionTile(
                        icon: Icons.receipt_long_outlined,
                        title: 'View orders',
                        subtitle: 'Monitor new customer purchases and fulfillment.',
                        onTap: () => context.push('/vendor/orders'),
                      ),
                      _ActionTile(
                        icon: Icons.storefront_outlined,
                        title: 'Edit storefront',
                        subtitle: 'Update store identity, contact details, and media.',
                        onTap: () => context.push('/vendor/profile'),
                      ),
                    ],
                  ),
                );

                final insightPanel = _Panel(
                  title: 'Workspace notes',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'The Flutter app now mirrors the seller-side structure of the Next.js frontend: registration, dashboard, product management, and order management all have dedicated routes.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Vendors can now edit storefront details, manage products, and update order flow from dedicated screens.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                );

                if (stacked) {
                  return Column(
                    children: [
                      actionsPanel,
                      const SizedBox(height: 16),
                      insightPanel,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: actionsPanel),
                    const SizedBox(width: 16),
                    Expanded(child: insightPanel),
                  ],
                );
              },
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => _DashboardLoadError(
        message: 'Dashboard error: $e',
        onRetry: () => ref.invalidate(vendorDashboardProvider),
      ),
    );
  }
}

class _DashboardLoadError extends StatelessWidget {
  const _DashboardLoadError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardEmptyState extends StatelessWidget {
  const _DashboardEmptyState({
    required this.title,
    required this.description,
    required this.primaryLabel,
    required this.primaryAction,
    this.secondaryLabel,
    this.secondaryAction,
    this.icon = Icons.storefront_rounded,
  });

  final String title;
  final String description;
  final String primaryLabel;
  final VoidCallback primaryAction;
  final String? secondaryLabel;
  final VoidCallback? secondaryAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: const Color(0x14000000)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: const Color(0xFFF4EFE6),
                  child: Icon(icon, color: const Color(0xFF121A23), size: 30),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: primaryAction,
                      child: Text(primaryLabel),
                    ),
                    if (secondaryLabel != null && secondaryAction != null)
                      OutlinedButton(
                        onPressed: secondaryAction,
                        child: Text(secondaryLabel!),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardStat {
  const _DashboardStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat});

  final _DashboardStat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x14000000)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF4EFE6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(stat.icon, color: const Color(0xFF121A23)),
          ),
          const SizedBox(height: 20),
          Text(
            stat.value,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            stat.label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0x14000000)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFCF7),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0x14000000)),
        ),
        child: Row(
          children: [
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFF4EFE6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: const Color(0xFF121A23)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded),
          ],
        ),
      ),
    );
  }
}
