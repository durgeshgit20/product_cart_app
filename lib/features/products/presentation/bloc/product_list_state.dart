import 'package:equatable/equatable.dart';
import '../../domain/entities/product.dart';

abstract class ProductListState extends Equatable {
  const ProductListState();

  @override
  List<Object?> get props => [];
}

class ProductListInitialState extends ProductListState {}

class ProductListLoadingState extends ProductListState {}

class ProductListLoadedState extends ProductListState {
  final List<Product> products;
  final bool isRefreshing;

  const ProductListLoadedState({
    required this.products,
    this.isRefreshing = false,
  });

  @override
  List<Object?> get props => [products, isRefreshing];
}

class ProductListEmptyState extends ProductListState {}

class ProductListErrorState extends ProductListState {
  final String errorMessage;

  const ProductListErrorState({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}
