import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/upload_file_data.dart';
import '../repository/vendor_repository.dart';
import 'vendor_dashboard_screen.dart';

class VendorRegisterScreen extends ConsumerStatefulWidget {
  const VendorRegisterScreen({super.key});

  @override
  ConsumerState<VendorRegisterScreen> createState() => _VendorRegisterScreenState();
}

class _VendorRegisterScreenState extends ConsumerState<VendorRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  UploadFileData? _logoFile;
  String? _logoName;
  UploadFileData? _bannerFile;
  String? _bannerName;
  bool _isLoading = false;
  bool _submitted = false;

  @override
  void dispose() {
    _storeNameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage({
    required bool isLogo,
  }) async {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to use the selected file on this platform.')),
        );
      }
      return;
    }

    setState(() {
      if (isLogo) {
        _logoFile = UploadFileData(
          name: file.name,
          path: file.path,
          bytes: file.bytes,
        );
        _logoName = file.name;
      } else {
        _bannerFile = UploadFileData(
          name: file.name,
          path: file.path,
          bytes: file.bytes,
        );
        _bannerName = file.name;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(vendorRepositoryProvider).register(
            storeName: _storeNameController.text.trim(),
            description: _descriptionController.text.trim(),
            phone: _phoneController.text.trim(),
            address: _addressController.text.trim(),
            storeLogo: _logoFile,
            storeBanner: _bannerFile,
          );
      ref.invalidate(vendorStatusProvider);
      if (mounted) {
        setState(() => _submitted = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vendor registration failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: const Color(0x14000000)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 42,
                      backgroundColor: Color(0x1F688254),
                      child: Icon(Icons.check_circle, size: 48, color: Color(0xFF2F6F4F)),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Your seller application is in review.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your storefront details have been submitted. Once approved, you can start listing products and managing orders from the vendor dashboard.',
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
                          onPressed: () => context.go('/vendor/dashboard'),
                          child: const Text('Go to dashboard'),
                        ),
                        OutlinedButton(
                          onPressed: () => context.go('/'),
                          child: const Text('Return home'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Seller onboarding')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 860;

                final introPanel = Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(36),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 60,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.storefront, color: Colors.white, size: 30),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Launch a store that feels as refined as the products you sell.',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Create your storefront identity, upload your brand assets, and prepare your workspace for product listings, customer chats, and order management.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                      const SizedBox(height: 28),
                      ...const [
                        _VendorInfoChip(text: 'Set your storefront name and contact details'),
                        SizedBox(height: 12),
                        _VendorInfoChip(text: 'Upload a recognizable logo and optional banner'),
                        SizedBox(height: 12),
                        _VendorInfoChip(text: 'Move into the vendor dashboard after review'),
                      ],
                    ],
                  ),
                );

                final formPanel = Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(color: const Color(0x14000000)),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Seller application',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _storeNameController,
                          decoration: const InputDecoration(labelText: 'Store name'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Store name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _FilePickerField(
                          label: 'Store logo',
                          fileName: _logoName,
                          onPressed: () => _pickImage(isLogo: true),
                        ),
                        const SizedBox(height: 16),
                        _FilePickerField(
                          label: 'Store banner',
                          fileName: _bannerName,
                          onPressed: () => _pickImage(isLogo: false),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(labelText: 'Store description'),
                          maxLines: 4,
                        ),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, fieldConstraints) {
                            final stackedFields = fieldConstraints.maxWidth < 640;

                            if (stackedFields) {
                              return Column(
                                children: [
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
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _phoneController,
                                    decoration: const InputDecoration(labelText: 'Phone'),
                                    keyboardType: TextInputType.phone,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _addressController,
                                    decoration: const InputDecoration(labelText: 'Business address'),
                                    maxLines: 2,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            child: Text(
                              _isLoading ? 'Submitting application...' : 'Submit seller application',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );

                if (stacked) {
                  return ListView(
                    children: [
                      introPanel,
                      const SizedBox(height: 16),
                      formPanel,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 9, child: introPanel),
                    const SizedBox(width: 20),
                    Expanded(flex: 11, child: formPanel),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _FilePickerField extends StatelessWidget {
  const _FilePickerField({
    required this.label,
    required this.fileName,
    required this.onPressed,
  });

  final String label;
  final String? fileName;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x14000000)),
      ),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF4EFE6),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.upload_file_outlined, color: Color(0xFF121A23)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  fileName ?? 'No file selected',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: onPressed,
            child: Text(fileName == null ? 'Upload' : 'Replace'),
          ),
        ],
      ),
    );
  }
}

class _VendorInfoChip extends StatelessWidget {
  const _VendorInfoChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
      ),
    );
  }
}
