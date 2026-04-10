import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/upload_file_data.dart';
import '../../../models/product_model.dart';
import 'vendor_products_screen.dart';
import '../repository/vendor_repository.dart';

class VendorProductEditorScreen extends ConsumerStatefulWidget {
  const VendorProductEditorScreen({super.key, this.product});

  final Product? product;

  @override
  ConsumerState<VendorProductEditorScreen> createState() => _VendorProductEditorScreenState();
}

class _VendorProductEditorScreenState extends ConsumerState<VendorProductEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _stockController = TextEditingController(text: '1');
  final List<UploadFileData?> _imageFiles = List<UploadFileData?>.filled(4, null);
  final List<String?> _imageNames = List<String?>.filled(4, null);

  bool _isActive = true;
  bool _isSubmitting = false;

  bool get _isEditMode => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    if (product == null) {
      return;
    }

    _titleController.text = product.title;
    _categoryController.text = product.categoryName ?? '';
    _descriptionController.text = product.description ?? '';
    _priceController.text = product.discountedPrice.toStringAsFixed(2);
    _originalPriceController.text = product.originalPrice.toStringAsFixed(2);
    _stockController.text = product.stock.toString();
    _isActive = product.isActive;

    final imageUrls = [product.img1, product.img2, product.img3, product.img4];
    for (var i = 0; i < imageUrls.length; i++) {
      final url = imageUrls[i];
      if (url != null && url.isNotEmpty) {
        _imageNames[i] = 'Current image ${i + 1}';
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(int index) async {
    try {
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
            const SnackBar(content: Text('Selected file path is unavailable on this platform.')),
          );
        }
        return;
      }

      setState(() {
        _imageFiles[index] = UploadFileData(
          name: file.name,
          path: file.path,
          bytes: file.bytes,
        );
        _imageNames[index] = file.name;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File picker failed: $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final payload = <String, dynamic>{
        'title': _titleController.text.trim(),
        'category': _categoryController.text.trim(),
        'discription': _descriptionController.text.trim(),
        'discountedPrice': double.parse(_priceController.text.trim()),
        'orginalPrice': double.parse(_originalPriceController.text.trim()),
        'stock': int.parse(_stockController.text.trim()),
        'is_active': _isActive.toString(),
      };

      for (var i = 0; i < _imageFiles.length; i++) {
        final file = _imageFiles[i];
        if (file != null) {
          if (file.bytes != null) {
            payload['img${i + 1}'] = MultipartFile.fromBytes(
              file.bytes!,
              filename: file.name,
            );
          } else if (file.path != null && file.path!.trim().isNotEmpty) {
            payload['img${i + 1}'] = await MultipartFile.fromFile(
              file.path!,
              filename: file.name,
            );
          }
        }
      }

      if (_isEditMode) {
        await ref.read(vendorRepositoryProvider).updateProduct(widget.product!.id, payload);
      } else {
        await ref.read(vendorRepositoryProvider).createProduct(payload);
      }
      ref.invalidate(vendorProductsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? 'Product updated successfully.'
                  : 'Product created successfully.',
            ),
          ),
        );
        context.go('/vendor/products');
      }
    } on DioException catch (e) {
      final errorData = e.response?.data;
      final message = errorData is Map<String, dynamic>
          ? (errorData['detail']?.toString() ??
              errorData.entries.map((entry) => '${entry.key}: ${entry.value}').join(', '))
          : e.message;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? 'Product update failed: $message'
                  : 'Product creation failed: $message',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? 'Product update failed: $e'
                  : 'Product creation failed: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditMode ? 'Edit product' : 'Add product')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < 860;

                  final mainPanel = Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: const Color(0x14000000)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditMode ? 'Edit product' : 'Create a new product',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _isEditMode
                              ? 'Update product details, pricing, inventory, visibility, and gallery assets for this listing.'
                              : 'Manage title, category, pricing, inventory, visibility, and gallery assets like the Next.js vendor workspace.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        LayoutBuilder(
                          builder: (context, fieldConstraints) {
                            final narrow = fieldConstraints.maxWidth < 620;

                            if (narrow) {
                              return Column(
                                children: [
                                  TextFormField(
                                    controller: _titleController,
                                    decoration: const InputDecoration(labelText: 'Product title'),
                                    validator: _requiredText('Title is required'),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _categoryController,
                                    decoration: const InputDecoration(labelText: 'Category'),
                                    validator: _requiredText('Category is required'),
                                  ),
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _titleController,
                                    decoration: const InputDecoration(labelText: 'Product title'),
                                    validator: _requiredText('Title is required'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _categoryController,
                                    decoration: const InputDecoration(labelText: 'Category'),
                                    validator: _requiredText('Category is required'),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(labelText: 'Description'),
                          maxLines: 5,
                        ),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, priceConstraints) {
                            final narrow = priceConstraints.maxWidth < 760;

                            if (narrow) {
                              return Column(
                                children: [
                                  TextFormField(
                                    controller: _originalPriceController,
                                    decoration: const InputDecoration(labelText: 'Original price'),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    validator: _requiredNumber('Original price is required'),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _priceController,
                                    decoration: const InputDecoration(labelText: 'Discounted price'),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    validator: _requiredNumber('Discounted price is required'),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _stockController,
                                    decoration: const InputDecoration(labelText: 'Stock'),
                                    keyboardType: TextInputType.number,
                                    validator: _requiredInt('Stock is required'),
                                  ),
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _originalPriceController,
                                    decoration: const InputDecoration(labelText: 'Original price'),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    validator: _requiredNumber('Original price is required'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _priceController,
                                    decoration: const InputDecoration(labelText: 'Discounted price'),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    validator: _requiredNumber('Discounted price is required'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _stockController,
                                    decoration: const InputDecoration(labelText: 'Stock'),
                                    keyboardType: TextInputType.number,
                                    validator: _requiredInt('Stock is required'),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  );

                  final sidePanel = Column(
                    children: [
                      Container(
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
                              'Status',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),
                            SwitchListTile(
                              value: _isActive,
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Product visible in storefront'),
                              subtitle: const Text('Turn this off to keep the listing hidden for now.'),
                              onChanged: (value) => setState(() => _isActive = value),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
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
                              'Gallery',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isEditMode
                                  ? 'Upload a new image to replace an existing one, or leave it unchanged.'
                                  : 'Upload up to four product images.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            LayoutBuilder(
                              builder: (context, galleryConstraints) {
                                final singleColumn = galleryConstraints.maxWidth < 320;
                                final tileWidth = singleColumn
                                    ? galleryConstraints.maxWidth
                                    : (galleryConstraints.maxWidth - 12) / 2;

                                return Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: List.generate(
                                    4,
                                    (index) => SizedBox(
                                      width: tileWidth,
                                      child: _ImagePickerTile(
                                        label: 'Image ${index + 1}',
                                        fileName: _imageNames[index],
                                        onTap: () => _pickImage(index),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          child: Text(
                            _isSubmitting
                                ? (_isEditMode ? 'Saving changes...' : 'Saving product...')
                                : (_isEditMode ? 'Save changes' : 'Create product'),
                          ),
                        ),
                      ),
                    ],
                  );

                  if (stacked) {
                    return Column(
                      children: [
                        mainPanel,
                        const SizedBox(height: 16),
                        sidePanel,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 13, child: mainPanel),
                      const SizedBox(width: 16),
                      Expanded(flex: 7, child: sidePanel),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? Function(String?) _requiredText(String message) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return message;
      }
      return null;
    };
  }

  String? Function(String?) _requiredNumber(String message) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return message;
      }
      if (double.tryParse(value) == null) {
        return 'Enter a valid number';
      }
      return null;
    };
  }

  String? Function(String?) _requiredInt(String message) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return message;
      }
      if (int.tryParse(value) == null) {
        return 'Enter a valid number';
      }
      return null;
    };
  }
}

class _ImagePickerTile extends StatelessWidget {
  const _ImagePickerTile({
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x14000000)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF4EFE6),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.image_outlined, color: Color(0xFF121A23)),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            fileName ?? 'No file selected',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onTap,
              child: Text(fileName == null ? 'Upload image' : 'Replace image'),
            ),
          ),
        ],
      ),
    );
  }
}
