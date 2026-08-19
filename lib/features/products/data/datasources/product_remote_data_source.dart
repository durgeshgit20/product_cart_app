import '../models/product_dto.dart';

abstract class IProductRemoteDataSource {
  Future<List<ProductDto>> getProducts({
    String? scenario,
  });
}
