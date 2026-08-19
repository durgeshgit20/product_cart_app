import 'package:flutter_test/flutter_test.dart';
import 'package:product_cart_app/features/products/data/models/product_dto.dart';
import 'package:product_cart_app/features/products/data/datasources/product_remote_data_source_impl.dart';
import 'package:product_cart_app/features/products/data/repositories/product_repository_impl.dart';
import 'package:product_cart_app/features/products/presentation/bloc/product_list_bloc.dart';
import 'package:product_cart_app/features/products/presentation/bloc/product_list_event.dart';
import 'package:product_cart_app/features/products/presentation/bloc/product_list_state.dart';
import 'package:product_cart_app/features/cart/presentation/bloc/cart_bloc.dart';

void main() {
  group('Product List & Cart Sync Tests with Real Scenarios', () {
    late ProductRemoteDataSourceImpl remoteDataSource;
    late ProductRepositoryImpl repository;
    late ProductListBloc productListBloc;
    late CartBloc cartBloc;

    setUp(() {
      remoteDataSource = ProductRemoteDataSourceImpl();
      repository = ProductRepositoryImpl(remoteDataSource: remoteDataSource);
      productListBloc = ProductListBloc(productRepository: repository);
      cartBloc = CartBloc(productRepository: repository);
    });

    tearDown(() {
      productListBloc.close();
      cartBloc.close();
    });

    test(
      'ProductDto toEntity correctly maps available flag to isOutOfStock',
      () {
        const dtoAvailable = ProductDto(
          id: 'P001',
          name: 'Premium Car Wash',
          description: 'Test',
          price: 699,
          imageUrl: 'https://picsum.photos/200',
          stockQuantity: 10,
          isOutOfStock: false,
        );

        final entity = dtoAvailable.toEntity();
        expect(entity.id, 'P001');
        expect(entity.price, 699.0);
        expect(entity.isOutOfStock, isFalse);
      },
    );

    test('Fetch with scenario: "error" emits ProductListErrorState', () async {
      expectLater(
        productListBloc.stream,
        emitsInOrder([
          isA<ProductListLoadingState>(),
          isA<ProductListErrorState>(),
        ]),
      );

      productListBloc.add(const FetchProductsEvent(scenario: 'error'));
    });
  });
}
