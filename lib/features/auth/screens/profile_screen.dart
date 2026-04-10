import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../models/user_model.dart';
import '../controller/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(authStateProvider);
    final userAsync = ref.watch(currentUserProvider);
    final vendorAsync = ref.watch(profileVendorStatusProvider);

    if (!isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('My profile')),
        body: _ProfileError(
          message: 'You are not signed in.',
          onRetry: () => context.go('/login'),
          actionLabel: 'Go to login',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My profile')),
      body: userAsync.when(
        data: (user) {
          final vendorStatus = vendorAsync.maybeWhen(
            data: (value) => value,
            orElse: () => const <String, dynamic>{},
          );

          return _ProfileContent(
            user: user,
            vendorStatus: vendorStatus,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => _ProfileError(
          message: 'Failed to load your profile: $e',
          onRetry: () => ref.invalidate(currentUserProvider),
        ),
      ),
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({
    required this.user,
    required this.vendorStatus,
  });

  final UserModel user;
  final Map<String, dynamic> vendorStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVendor = vendorStatus['is_vendor'] == true;
    final isApproved = vendorStatus['is_approved'] == true;
    final vendorData = _extractVendorData(vendorStatus);
    final storeName = _readVendorText(vendorData, 'store_name');
    final storeDescription = _readVendorText(vendorData, 'store_description');
    final resolvedEmail = user.email.trim().isNotEmpty ? user.email.trim() : 'No email available';
    final displayName = (user.name != null && user.name!.trim().isNotEmpty)
        ? user.name!.trim()
        : (user.email.trim().isNotEmpty ? user.email.trim() : 'User account');
    final avatarLetter = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    final actionCards = [
      _ProfileAction(
        title: 'Edit profile',
        description: 'Update your name and profile picture.',
        icon: Icons.manage_accounts_outlined,
        route: '/profile/edit',
      ),
      _ProfileAction(
        title: 'Orders',
        description: 'Review recent purchases and track delivery progress.',
        icon: Icons.receipt_long_outlined,
        route: '/orders',
      ),
      _ProfileAction(
        title: 'Saved items',
        description: 'Return to products you bookmarked for later.',
        icon: Icons.favorite_border_rounded,
        route: '/wishlist',
      ),
      _ProfileAction(
        title: 'Messages',
        description: isVendor
            ? 'Reply to customer conversations from your storefront.'
            : 'Talk to sellers about products and support.',
        icon: Icons.forum_outlined,
        route: '/chat',
      ),
      _ProfileAction(
        title: isVendor ? 'Vendor Dashboard' : 'Become a Seller',
        description: isVendor
            ? 'Manage store performance, products, orders, and profile.'
            : 'Open your own storefront and start selling.',
        icon: Icons.storefront_outlined,
        route: isVendor ? '/vendor/dashboard' : '/vendor/register',
      ),
      _ProfileAction(
        title: 'Cart',
        description: 'Return to saved selections and continue checkout.',
        icon: Icons.shopping_bag_outlined,
        route: '/cart',
      ),
      if (isVendor)
        const _ProfileAction(
          title: 'Edit Store',
          description: 'Update your storefront name, contact info, and brand assets.',
          icon: Icons.edit_outlined,
          route: '/vendor/profile',
        ),
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(36),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    alignment: Alignment.center,
                    clipBehavior: Clip.antiAlias,
                    child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: user.avatarUrl!,
                            fit: BoxFit.cover,
                            width: 80,
                            height: 80,
                            errorWidget: (context, url, error) => Text(
                              avatarLetter,
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                    color: Colors.white,
                                  ),
                            ),
                          )
                        : Text(
                            avatarLetter,
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  color: Colors.white,
                                ),
                          ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: Colors.white70,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          displayName,
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          resolvedEmail,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white70,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatusChip(
                    text: isVendor
                        ? (isApproved ? 'Seller approved' : 'Seller pending')
                        : 'Customer account',
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(authStateProvider.notifier).logout();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign out'),
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
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 900;
            final overview = _InfoPanel(
              title: 'Overview',
              body:
                  'Move between purchases, conversations, and storefront tools from one structured account hub.',
              dark: false,
            );
            final status = _InfoPanel(
              title: 'Status',
              body: isVendor
                  ? (isApproved
                      ? 'Your store is live. Use the dashboard to manage products, orders, and customer chats.'
                      : 'Your store is under review. Once approved, the seller workspace will be fully active.')
                  : 'You are shopping as a customer. Switch to seller mode whenever you are ready to open a storefront.',
              dark: true,
            );
            final sellerPanel = isVendor
                ? _InfoPanel(
                    title: storeName ?? 'Storefront',
                    body: storeDescription ??
                        'Your vendor account is active. Open the vendor dashboard to manage products and orders.',
                    dark: false,
                  )
                : null;

            if (stacked) {
              return Column(
                children: [
                  overview,
                  const SizedBox(height: 16),
                  status,
                  if (sellerPanel != null) ...[
                    const SizedBox(height: 16),
                    sellerPanel,
                  ],
                ],
              );
            }

            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: overview),
                    const SizedBox(width: 16),
                    Expanded(child: status),
                  ],
                ),
                if (sellerPanel != null) ...[
                  const SizedBox(height: 16),
                  sellerPanel,
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final isSingleColumn = constraints.maxWidth < 720;
            final cardWidth = isSingleColumn
                ? constraints.maxWidth
                : (constraints.maxWidth - 16) / 2;

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: actionCards
                  .map(
                    (action) => SizedBox(
                      width: cardWidth,
                      child: _ProfileActionCard(action: action),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

Map<String, dynamic>? _extractVendorData(Map<String, dynamic> vendorStatus) {
  final vendor = vendorStatus['vendor'];
  if (vendor is Map<String, dynamic>) {
    return vendor;
  }

  if (vendorStatus['store_name'] != null || vendorStatus['store_description'] != null) {
    return vendorStatus;
  }

  return null;
}

String? _readVendorText(Map<String, dynamic>? vendorData, String key) {
  if (vendorData == null) {
    return null;
  }

  final value = vendorData[key];
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }

  return null;
}

class _ProfileError extends ConsumerWidget {
  const _ProfileError({
    required this.message,
    required this.onRetry,
    this.actionLabel = 'Retry',
  });

  final String message;
  final VoidCallback onRetry;
  final String actionLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(actionLabel),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                await ref.read(authStateProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              child: const Text('Reset session'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAction {
  const _ProfileAction({
    required this.title,
    required this.description,
    required this.icon,
    required this.route,
  });

  final String title;
  final String description;
  final IconData icon;
  final String route;
}

class _ProfileActionCard extends StatelessWidget {
  const _ProfileActionCard({required this.action});

  final _ProfileAction action;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(action.route),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(22),
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
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF4EFE6),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(action.icon, color: const Color(0xFF121A23)),
            ),
            const SizedBox(height: 24),
            Text(
              action.title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            Text(
              action.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF475569),
                  ),
            ),
            const SizedBox(height: 18),
            Text(
              'Open section',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF64748B),
                    fontSize: 11,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.title,
    required this.body,
    required this.dark,
  });

  final String title;
  final String body;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: dark ? Colors.transparent : const Color(0x14000000),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: dark ? Colors.white : const Color(0xFF121A23),
                ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: dark ? Colors.white70 : const Color(0xFF475569),
                ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontSize: 11,
            ),
      ),
    );
  }
}
