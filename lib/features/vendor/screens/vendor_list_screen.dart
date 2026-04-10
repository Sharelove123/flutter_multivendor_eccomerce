import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../repository/vendor_repository.dart';
import '../../../models/vendor_model.dart';

final vendorListProvider = FutureProvider.autoDispose<List<VendorModel>>((ref) async {
  return ref.read(vendorRepositoryProvider).getVendorList();
});

class VendorListScreen extends ConsumerWidget {
  const VendorListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(vendorListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Store Directory')),
      body: listAsync.when(
        data: (vendors) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: vendors.length,
          itemBuilder: (context, index) {
            final v = vendors[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 4,
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.store),
                ),
                title: Text(v.storeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                subtitle: Text('Products: ${v.productCount} | Rating: ${v.averageRating}★\n${v.storeDescription ?? ""}'),
                isThreeLine: true,
                onTap: () {
                  if (v.slug != null) {
                    context.push('/vendor/store/${v.slug}', extra: v);
                  }
                },
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Failed to load vendors: $e')),
      ),
    );
  }
}
