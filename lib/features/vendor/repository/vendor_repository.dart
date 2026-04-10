import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/upload_file_data.dart';
import '../../../core/api_client.dart';
import '../../../models/product_model.dart';
import '../../../models/order_model.dart';
import '../../../models/vendor_model.dart';

final vendorRepositoryProvider = Provider<VendorRepository>((ref) {
  return VendorRepository(ref.read(dioProvider));
});

class VendorRepository {
  final Dio _dio;

  VendorRepository(this._dio);

  Future<Map<String, dynamic>> checkStatus() async {
    try {
      final response = await _dio.get('/api/vendor/status/').timeout(
            const Duration(seconds: 15),
          );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (e) {
      throw Exception('Unable to load vendor status: $e');
    }
  }

  Future<void> register({
    required String storeName,
    required String description,
    required String phone,
    required String address,
    UploadFileData? storeLogo,
    UploadFileData? storeBanner,
  }) async {
    final payload = <String, dynamic>{
      'store_name': storeName,
      'store_description': description,
      'phone': phone,
      'address': address,
    };

    final logoFile = await _toMultipartFile(storeLogo);
    if (logoFile != null) {
      payload['store_logo'] = logoFile;
    }

    final bannerFile = await _toMultipartFile(storeBanner);
    if (bannerFile != null) {
      payload['store_banner'] = bannerFile;
    }

    await _dio.post(
      '/api/vendor/register/',
      data: FormData.fromMap(payload),
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      ),
    );
  }

  Future<Map<String, dynamic>> getDashboardMetrics() async {
    try {
      final response = await _dio.get('/api/vendor/me/dashboard/').timeout(
            const Duration(seconds: 15),
          );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (e) {
      throw Exception('Unable to load vendor dashboard: $e');
    }
  }

  Future<List<Product>> getMyProducts() async {
    try {
      final response = await _dio.get('/api/vendor/me/products/').timeout(
            const Duration(seconds: 15),
          );
      final data = response.data;
      final list = data is List ? data : (data['results'] as List? ?? const []);
      return list.map((x) => Product.fromJson(x)).toList();
    } catch (e) {
      throw Exception('Unable to load vendor products: $e');
    }
  }

  Future<void> createProduct(Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data);
    await _dio.post(
      '/api/vendor/me/products/',
      data: FormData.fromMap(payload),
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      ),
    );
  }

  Future<void> updateProduct(int productId, Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data);
    await _dio.patch(
      '/api/vendor/me/products/$productId/',
      data: FormData.fromMap(payload),
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      ),
    );
  }

  Future<void> deleteProduct(int productId) async {
    await _dio.delete('/api/vendor/me/products/$productId/').timeout(
          const Duration(seconds: 15),
        );
  }

  Future<void> updateStoreProfile({
    required String storeName,
    required String description,
    required String phone,
    required String address,
    UploadFileData? storeLogo,
    UploadFileData? storeBanner,
  }) async {
    final payload = <String, dynamic>{
      'store_name': storeName,
      'store_description': description,
      'phone': phone,
      'address': address,
    };

    final logoFile = await _toMultipartFile(storeLogo);
    if (logoFile != null) {
      payload['store_logo'] = logoFile;
    }

    final bannerFile = await _toMultipartFile(storeBanner);
    if (bannerFile != null) {
      payload['store_banner'] = bannerFile;
    }

    await _dio.patch(
      '/api/vendor/me/profile/',
      data: FormData.fromMap(payload),
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      ),
    );
  }

  Future<List<OrderModel>> getMyOrders() async {
    try {
      final response = await _dio.get('/api/vendor/me/orders/').timeout(
            const Duration(seconds: 15),
          );
      final data = response.data;
      final list = data is List ? data : (data['results'] as List? ?? const []);
      return list.map((x) => OrderModel.fromJson(x)).toList();
    } catch (e) {
      throw Exception('Unable to load vendor orders: $e');
    }
  }

  Future<void> updateOrderStatus(int orderId, String status) async {
    try {
      await _dio.patch(
        '/api/vendor/me/orders/$orderId/status/',
        data: {'status': status},
      ).timeout(const Duration(seconds: 15));
    } catch (e) {
      throw Exception('Unable to update order status: $e');
    }
  }

  Future<List<VendorModel>> getVendorList() async {
    final response = await _dio.get('/api/vendor/list/');
    return (response.data as List).map((x) => VendorModel.fromJson(x)).toList();
  }

  Future<List<Product>> getVendorStorefrontProducts(String slug) async {
    final response = await _dio.get('/api/vendor/store/$slug/products/');
    return (response.data as List).map((x) => Product.fromJson(x)).toList();
  }

  Future<MultipartFile?> _toMultipartFile(UploadFileData? file) async {
    if (file == null) {
      return null;
    }

    if (file.bytes != null) {
      return MultipartFile.fromBytes(file.bytes!, filename: file.name);
    }

    if (file.path != null && file.path!.trim().isNotEmpty) {
      return MultipartFile.fromFile(file.path!, filename: file.name);
    }

    return null;
  }
}
