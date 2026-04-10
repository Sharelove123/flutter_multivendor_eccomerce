import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controller/cart_controller.dart';
import '../repository/cart_repository.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalController = TextEditingController();
  
  bool _isLoading = false;

  Future<void> _placeOrder() async {
    final items = ref.read(cartProvider);
    if (items.isEmpty) return;

    if (_streetController.text.isEmpty || _cityController.text.isEmpty || _stateController.text.isEmpty || _postalController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill out all address fields.')));
        return;
    }

    setState(() => _isLoading = true);
    
    try {
      final addressData = {
        'street_name': _streetController.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'postal_code': _postalController.text,
        'country': 'United States',
      };

      await ref.read(cartRepositoryProvider).checkout(items, addressData, 'COD');
      
      ref.read(cartProvider.notifier).clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order placed successfully!')));
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Checkout failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout (COD)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Shipping Address', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: _streetController, decoration: const InputDecoration(labelText: 'Street Address')),
            const SizedBox(height: 16),
            TextField(controller: _cityController, decoration: const InputDecoration(labelText: 'City')),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextField(controller: _stateController, decoration: const InputDecoration(labelText: 'State'))),
                const SizedBox(width: 16),
                Expanded(child: TextField(controller: _postalController, decoration: const InputDecoration(labelText: 'ZIP Code'))),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: const Row(
                children: [
                   Icon(Icons.local_shipping, color: Colors.green),
                   SizedBox(width: 16),
                   Expanded(child: Text('Payment Method: Cash on Delivery (COD)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _placeOrder,
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Place Order'),
            ),
          ],
        ),
      ),
    );
  }
}
