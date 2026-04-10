class VendorModel {
  final int id;
  final dynamic user; 
  final String storeName;
  final String? slug;
  final String? storeDescription;
  final String? storeLogo;
  final String? storeBanner;
  final String? phone;
  final String? address;
  final bool isApproved;
  final double commissionRate;
  final double totalRevenue;
  final int totalSalesCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int productCount;
  final double averageRating;

  VendorModel({
    required this.id,
    this.user,
    required this.storeName,
    this.slug,
    this.storeDescription,
    this.storeLogo,
    this.storeBanner,
    this.phone,
    this.address,
    this.isApproved = false,
    this.commissionRate = 10.0,
    this.totalRevenue = 0.0,
    this.totalSalesCount = 0,
    this.createdAt,
    this.updatedAt,
    this.productCount = 0,
    this.averageRating = 0.0,
  });

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    return VendorModel(
      id: json['id'] ?? 0,
      user: json['user'],
      storeName: json['store_name'] ?? '',
      slug: json['slug'],
      storeDescription: json['store_description'],
      storeLogo: json['store_logo'],
      storeBanner: json['store_banner'],
      phone: json['phone'],
      address: json['address'],
      isApproved: json['is_approved'] ?? false,
      commissionRate: (json['commission_rate'] ?? 10.0).toDouble(),
      totalRevenue: (json['total_revenue'] ?? 0.0).toDouble(),
      totalSalesCount: json['total_sales_count'] ?? 0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
      productCount: json['product_count'] ?? 0,
      averageRating: (json['average_rating'] ?? 0.0).toDouble(),
    );
  }
}
