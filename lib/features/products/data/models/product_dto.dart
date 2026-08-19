import 'package:equatable/equatable.dart';
import '../../domain/entities/product.dart';

class ProductDto extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final int stockQuantity;
  final bool isOutOfStock;

  const ProductDto({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.stockQuantity,
    this.isOutOfStock = false,
  });

  factory ProductDto.fromJson(Map<String, dynamic> json) {
    final bool isAvailable = json['available'] as bool? ?? true;
    return ProductDto(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? 'Professional vehicle service package.',
      price: (json['price'] as num? ?? 0).toDouble(),
      imageUrl: json['imageUrl'] as String? ?? 'https://picsum.photos/200?image=10',
      stockQuantity: isAvailable ? (json['stockQuantity'] as int? ?? 10) : 0,
      isOutOfStock: !isAvailable,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'stockQuantity': stockQuantity,
      'isOutOfStock': isOutOfStock,
    };
  }

  Product toEntity() {
    return Product(
      id: id,
      name: name,
      description: description,
      price: price,
      imageUrl: imageUrl,
      stockQuantity: stockQuantity,
      isOutOfStock: isOutOfStock,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        price,
        imageUrl,
        stockQuantity,
        isOutOfStock,
      ];
}
