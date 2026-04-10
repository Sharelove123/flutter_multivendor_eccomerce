import 'package:multivendoreccommerce/models/product_model.dart';

class AddressModel {
  final int id;
  final String country;
  final String state;
  final String city;
  final String streetName;
  final String? apartmentNumber;
  final String postalCode;

  AddressModel({
    required this.id,
    this.country = 'United States',
    required this.state,
    required this.city,
    required this.streetName,
    this.apartmentNumber,
    required this.postalCode,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] ?? 0,
      country: json['country'] ?? 'United States',
      state: json['state'] ?? '',
      city: json['city'] ?? '',
      streetName: json['street_name'] ?? '',
      apartmentNumber: json['apartment_number'],
      postalCode: json['postal_code'] ?? '',
    );
  }
}

class OrderItemModel {
  final int id;
  final dynamic orderId;
  final dynamic product; // Product ID or Product Object
  final dynamic vendor; // Vendor ID or VendorModel
  final int quantity;

  OrderItemModel({
    required this.id,
    this.orderId,
    this.product,
    this.vendor,
    this.quantity = 1,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    dynamic prod = json['product'];
    if (prod is Map<String, dynamic>) {
      prod = Product.fromJson(prod);
    }
    return OrderItemModel(
      id: json['id'] ?? 0,
      orderId: json['Order'],
      product: prod,
      vendor: json['vendor_name'] ?? json['vendor'],
      quantity: json['quantity'] ?? 1,
    );
  }
}

class OrderModel {
  final int id;
  final dynamic user;
  final dynamic address; // ID or AddressModel
  final bool delivered;
  final bool paid;
  final String status;
  final DateTime? createdAt;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    this.user,
    this.address,
    this.delivered = false,
    this.paid = false,
    required this.status,
    this.createdAt,
    this.items = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    dynamic addr = json['address'];
    if (addr is Map<String, dynamic>) {
      addr = AddressModel.fromJson(addr);
    }
    return OrderModel(
      id: json['id'] ?? 0,
      user: json['user'],
      address: addr,
      delivered: json['delivered'] ?? false,
      paid: json['paid'] ?? false,
      status: json['status'] ?? 'PENDING',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      items:
          (json['Order_items'] as List<dynamic>?)
              ?.map((item) => OrderItemModel.fromJson(item))
              .toList() ??
          [],
    );
  }
}
