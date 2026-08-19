import 'package:equatable/equatable.dart';
import '../../domain/repositories/i_product_repository.dart';

abstract class ProductListEvent extends Equatable {
  const ProductListEvent();

  @override
  List<Object?> get props => [];
}

class FetchProductsEvent extends ProductListEvent {
  final String? scenario;

  const FetchProductsEvent({this.scenario});

  @override
  List<Object?> get props => [scenario];
}

class RefreshProductsEvent extends ProductListEvent {
  final String? scenario;

  const RefreshProductsEvent({this.scenario});

  @override
  List<Object?> get props => [scenario];
}

class SwitchRepositoryEvent extends ProductListEvent {
  final IProductRepository newRepository;
  final String? scenario;

  const SwitchRepositoryEvent({
    required this.newRepository,
    this.scenario,
  });

  @override
  List<Object?> get props => [newRepository, scenario];
}
