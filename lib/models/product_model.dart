class Product {
  final int id;
  final String title;
  final String? categoryName;
  final double? rating;
  final double originalPrice;
  final double discountedPrice;
  final String? description;
  final String? img1;
  final String? img2;
  final String? img3;
  final String? img4;
  final double? discountPercentage;
  final String? vendorName;
  final String? vendorLogo;
  final int stock;
  final bool isActive;

  Product({
    required this.id,
    required this.title,
    this.categoryName,
    this.rating,
    required this.originalPrice,
    required this.discountedPrice,
    this.description,
    this.img1,
    this.img2,
    this.img3,
    this.img4,
    this.discountPercentage,
    this.vendorName,
    this.vendorLogo,
    this.stock = 0,
    this.isActive = true,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      title: json['title'] ?? 'Unknown',
      categoryName: _readCategoryName(json),
      rating: json['rateing']?.toDouble(),
      originalPrice: (json['orginalPrice'] ?? 0).toDouble(),
      discountedPrice: (json['discountedPrice'] ?? 0).toDouble(),
      description: json['discription'],
      img1: json['imagelist']?['img1'],
      img2: json['imagelist']?['img2'],
      img3: json['imagelist']?['img3'],
      img4: json['imagelist']?['img4'],
      discountPercentage: json['get_discount_percentage']?.toDouble(),
      vendorName: json['vendor']?['store_name'],
      vendorLogo: json['vendor']?['store_logo'],
      stock: json['stock'] ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }

  static String? _readCategoryName(Map<String, dynamic> json) {
    final category = json['category'];

    if (category is Map<String, dynamic>) {
      final name = category['name'];
      if (name is String && name.trim().isNotEmpty) {
        return name.trim();
      }
    }

    if (category is String && category.trim().isNotEmpty) {
      return category.trim();
    }

    final categoryName = json['category_name'];
    if (categoryName is String && categoryName.trim().isNotEmpty) {
      return categoryName.trim();
    }

    return null;
  }
}
