import 'package:flutter/material.dart';

import '../../../models/order_model.dart';
import '../../../models/product_model.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final status = order.status.toUpperCase();
    final timeline = _buildTimeline(status);

    return Scaffold(
      appBar: AppBar(title: Text('Order #${order.id}')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SummaryCard(order: order),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Status timeline',
            child: Column(
              children: timeline,
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Items',
            child: Column(
              children: order.items.map((item) {
                final product =
                    item.product is Product ? item.product as Product : null;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4EFE6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: product?.img1 != null && product!.img1!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                  product.img1!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.image_not_supported_outlined),
                                ),
                              )
                            : const Icon(Icons.shopping_bag_outlined),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product?.title ?? 'Product #${item.product}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Seller: ${item.vendor ?? "Platform"}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Qty ${item.quantity}',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTimeline(String status) {
    const statuses = ['PENDING', 'PROCESSING', 'SHIPPED', 'DELIVERED'];
    final currentIndex = statuses.indexOf(status);
    final cancelled = status == 'CANCELLED';

    return [
      for (var i = 0; i < statuses.length; i++)
        _TimelineTile(
          title: statuses[i],
          description: _timelineMessage(statuses[i]),
          isDone: !cancelled && currentIndex >= i,
          isCurrent: !cancelled && currentIndex == i,
          isLast: i == statuses.length - 1 && !cancelled,
        ),
      if (cancelled)
        const _TimelineTile(
          title: 'CANCELLED',
          description: 'This order was cancelled before completion.',
          isDone: true,
          isCurrent: true,
          isLast: true,
          isCancelled: true,
        ),
    ];
  }

  String _timelineMessage(String status) {
    switch (status) {
      case 'PENDING':
        return 'Your order was placed successfully.';
      case 'PROCESSING':
        return 'The vendor is preparing your items.';
      case 'SHIPPED':
        return 'The package is on the way.';
      case 'DELIVERED':
        return 'The vendor marked the order as delivered.';
      default:
        return '';
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.order});

  final OrderModel order;

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'PROCESSING':
        return Colors.blue;
      case 'SHIPPED':
        return Colors.purple;
      case 'DELIVERED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(order.status);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x14000000)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Current status',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  order.status,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 18,
            runSpacing: 10,
            children: [
              Text(
                order.createdAt != null
                    ? 'Placed on ${order.createdAt!.toLocal().toString().split(".").first}'
                    : 'Placed date unavailable',
              ),
              Text(order.paid ? 'Payment: Paid' : 'Payment: COD'),
              Text('Items: ${order.items.length}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.title,
    required this.description,
    required this.isDone,
    required this.isCurrent,
    required this.isLast,
    this.isCancelled = false,
  });

  final String title;
  final String description;
  final bool isDone;
  final bool isCurrent;
  final bool isLast;
  final bool isCancelled;

  @override
  Widget build(BuildContext context) {
    final color = isCancelled
        ? Colors.red
        : isCurrent
            ? Theme.of(context).colorScheme.primary
            : isDone
                ? Colors.green
                : Colors.grey;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              height: 22,
              width: 22,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(
                isCancelled
                    ? Icons.close_rounded
                    : isDone
                        ? Icons.check_rounded
                        : Icons.circle,
                size: 12,
                color: color,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 42,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: isDone ? color.withValues(alpha: 0.35) : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(description, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
