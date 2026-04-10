import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/upload_file_data.dart';
import '../../auth/controller/auth_controller.dart';
import '../repository/vendor_repository.dart';
import 'vendor_dashboard_screen.dart';

class VendorProfileEditorScreen extends ConsumerStatefulWidget {
  const VendorProfileEditorScreen({super.key});

  @override
  ConsumerState<VendorProfileEditorScreen> createState() =>
      _VendorProfileEditorScreenState();
}

class _VendorProfileEditorScreenState
    extends ConsumerState<VendorProfileEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  UploadFileData? _logoFile;
  String? _logoName;
  UploadFileData? _bannerFile;
  String? _bannerName;
  bool _initialized = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _storeNameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _seed(Map<String, dynamic> status) {
    if (_initialized) {
      return;
    }
    final vendor = status['vendor'] is Map<String, dynamic>
        ? status['vendor'] as Map<String, dynamic>
        : status;
    _storeNameController.text = (vendor['store_name'] ?? '').toString();
    _descriptionController.text = (vendor['store_description'] ?? '').toString();
    _phoneController.text = (vendor['phone'] ?? '').toString();
    _addressController.text = (vendor['address'] ?? '').toString();
    _logoName = (vendor['store_logo'] ?? '').toString().isEmpty ? null : 'Current logo';
    _bannerName =
        (vendor['store_banner'] ?? '').toString().isEmpty ? null : 'Current banner';
    _initialized = true;
  }

  Future<void> _pickImage({required bool isLogo}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.single;
    if (file.path == null && file.bytes == null) {
      return;
    }

    setState(() {
      final data = UploadFileData(
        name: file.name,
        path: file.path,
        bytes: file.bytes,
      );
      if (isLogo) {
        _logoFile = data;
        _logoName = file.name;
      } else {
        _bannerFile = data;
        _bannerName = file.name;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(vendorRepositoryProvider).updateStoreProfile(
            storeName: _storeNameController.text.trim(),
            description: _descriptionController.text.trim(),
            phone: _phoneController.text.trim(),
            address: _addressController.text.trim(),
            storeLogo: _logoFile,
            storeBanner: _bannerFile,
          );
      ref.invalidate(vendorStatusProvider);
      ref.invalidate(profileVendorStatusProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Store profile updated.')),
        );
        context.go('/vendor/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update store profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(profileVendorStatusProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit storefront')),
      body: statusAsync.when(
        data: (status) {
          _seed(status);
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: const Color(0x14000000)),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Store details',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Update your storefront identity, contact information, and visual assets.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _storeNameController,
                          decoration: const InputDecoration(labelText: 'Store name'),
                          validator: (value) => value == null || value.trim().isEmpty
                              ? 'Store name is required'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(labelText: 'Store description'),
                          maxLines: 4,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(labelText: 'Phone'),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(labelText: 'Business address'),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        _PickerRow(
                          label: 'Store logo',
                          fileName: _logoName,
                          onTap: () => _pickImage(isLogo: true),
                        ),
                        const SizedBox(height: 16),
                        _PickerRow(
                          label: 'Store banner',
                          fileName: _bannerName,
                          onTap: () => _pickImage(isLogo: false),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _save,
                            child: Text(
                              _isSaving ? 'Saving changes...' : 'Save storefront changes',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Failed to load vendor profile: $e')),
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.label,
    required this.fileName,
    required this.onTap,
  });

  final String label;
  final String? fileName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x14000000)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  fileName ?? 'No replacement selected',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onTap,
            child: Text(fileName == null ? 'Upload' : 'Replace'),
          ),
        ],
      ),
    );
  }
}
