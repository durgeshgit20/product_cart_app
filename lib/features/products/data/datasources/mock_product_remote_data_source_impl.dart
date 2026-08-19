import 'dart:async';
import 'package:injectable/injectable.dart';
import '../models/product_dto.dart';
import 'product_remote_data_source.dart';

@Environment('mock')
@LazySingleton(as: IProductRemoteDataSource)
class MockProductRemoteDataSourceImpl implements IProductRemoteDataSource {
  final List<ProductDto> _mockProducts = [
    const ProductDto(
      id: 'mock-1',
      name: 'Mock Wireless Headphones',
      description: 'High quality noise cancelling headphones (Mock Data)',
      price: 199.99,
      imageUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=500',
      stockQuantity: 15,
      isOutOfStock: false,
    ),
    const ProductDto(
      id: 'mock-2',
      name: 'Mock Smart Watch',
      description: 'Fitness tracking smartwatch with heart rate monitor (Mock Data)',
      price: 149.50,
      imageUrl: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=500',
      stockQuantity: 8,
      isOutOfStock: false,
    ),
    const ProductDto(
      id: 'mock-3',
      name: 'Mock Ergonomic Keyboard',
      description: 'Mechanical keyboard designed for long typing sessions (Mock Data)',
      price: 89.99,
      imageUrl: 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=500',
      stockQuantity: 0,
      isOutOfStock: true,
    ),
    const ProductDto(
      id: 'mock-4',
      name: 'Mock Portable Speaker',
      description: 'Waterproof Bluetooth speaker with deep bass (Mock Data)',
      price: 59.99,
      imageUrl: 'https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?w=500',
      stockQuantity: 20,
      isOutOfStock: false,
    ),
  ];

  @override
  Future<List<ProductDto>> getProducts({String? scenario}) async {
    // Simulate slight network delay
    await Future.delayed(const Duration(milliseconds: 600));

    if (scenario == 'error') {
      throw Exception('Mock API Error: Failed to fetch mock products.');
    } else if (scenario == 'empty') {
      return [];
    } else if (scenario == 'updated') {
      return _mockProducts.map((dto) {
        if (dto.id == 'mock-1') {
          return ProductDto(
            id: dto.id,
            name: dto.name,
            description: dto.description,
            price: 179.99, // Updated price on scenario=updated
            imageUrl: dto.imageUrl,
            stockQuantity: dto.stockQuantity,
            isOutOfStock: dto.isOutOfStock,
          );
        }
        return dto;
      }).toList();
    } else if (scenario == 'normal' || scenario == null) {
      return _mockProducts;
    }

    return _mockProducts;
  }
}
