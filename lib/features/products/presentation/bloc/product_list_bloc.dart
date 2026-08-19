import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/i_product_repository.dart';
import 'product_list_event.dart';
import 'product_list_state.dart';

@injectable
class ProductListBloc extends Bloc<ProductListEvent, ProductListState> {
  IProductRepository productRepository;

  ProductListBloc({required this.productRepository})
      : super(ProductListInitialState()) {
    on<FetchProductsEvent>(_onFetchProducts);
    on<RefreshProductsEvent>(_onRefreshProducts);
    on<SwitchRepositoryEvent>(_onSwitchRepository);
  }

  Future<void> _onSwitchRepository(
    SwitchRepositoryEvent event,
    Emitter<ProductListState> emit,
  ) async {
    productRepository = event.newRepository;
    add(FetchProductsEvent(scenario: event.scenario));
  }

  Future<void> _onFetchProducts(
    FetchProductsEvent event,
    Emitter<ProductListState> emit,
  ) async {
    emit(ProductListLoadingState());
    try {
      final products = await productRepository.fetchProducts(
        scenario: event.scenario,
      );
      if (products.isEmpty) {
        emit(ProductListEmptyState());
      } else {
        emit(ProductListLoadedState(products: products));
      }
    } catch (e) {
      emit(ProductListErrorState(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  Future<void> _onRefreshProducts(
    RefreshProductsEvent event,
    Emitter<ProductListState> emit,
  ) async {
    try {
      final products = await productRepository.fetchProducts(
        scenario: event.scenario,
      );
      if (products.isEmpty) {
        emit(ProductListEmptyState());
      } else {
        emit(ProductListLoadedState(products: products));
      }
    } catch (e) {
      emit(ProductListErrorState(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }
}
