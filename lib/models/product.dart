class Product {
  final String id;
  final String name;
  final double price;
  final String? imageUrl;
  final String? qrCode;
  final int warrantyPeriodMonths;
  final String? category;
  final String? technicalSpecs;
  final DateTime createdAt;

  // Cart/Sale specific fields (not in DB products table)
  int? cartWarrantyMonths;
  bool? cartIncludesInstallation;
  double? cartSalePrice;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
    this.qrCode,
    required this.warrantyPeriodMonths,
    this.category,
    this.technicalSpecs,
    required this.createdAt,
    this.cartWarrantyMonths,
    this.cartIncludesInstallation,
    this.cartSalePrice,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      name: json['name'] ?? 'No Name',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['image_url'],
      qrCode: json['qr_code'],
      warrantyPeriodMonths: json['warranty_period_months'] ?? 12,
      category: json['category'],
      technicalSpecs: json['technical_specs'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'image_url': imageUrl,
      'qr_code': qrCode,
      'warranty_period_months': warrantyPeriodMonths,
      'category': category,
      'technical_specs': technicalSpecs,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helper to clone for cart
  Product copyWith({
    int? cartWarrantyMonths,
    bool? cartIncludesInstallation,
    double? cartSalePrice,
  }) {
    return Product(
      id: id,
      name: name,
      price: price,
      imageUrl: imageUrl,
      qrCode: qrCode,
      warrantyPeriodMonths: warrantyPeriodMonths,
      category: category,
      technicalSpecs: technicalSpecs,
      createdAt: createdAt,
      cartWarrantyMonths: cartWarrantyMonths ?? this.cartWarrantyMonths,
      cartIncludesInstallation: cartIncludesInstallation ?? this.cartIncludesInstallation,
      cartSalePrice: cartSalePrice ?? this.cartSalePrice,
    );
  }
}
