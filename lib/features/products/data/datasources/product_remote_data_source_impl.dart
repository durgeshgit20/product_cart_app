import 'dart:async';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../models/product_dto.dart';
import 'product_remote_data_source.dart';

@Environment('dev')
@Environment('prod')
@LazySingleton(as: IProductRemoteDataSource)
class ProductRemoteDataSourceImpl implements IProductRemoteDataSource {
  final Dio dio;
  static const String _baseUrl =
      'https://d998-203-192-225-119.ngrok-free.app/products';

  ProductRemoteDataSourceImpl({Dio? dio}) : dio = dio ?? Dio();

  @override
  Future<List<ProductDto>> getProducts({
    String? scenario,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (scenario != null && scenario.isNotEmpty) {
        queryParams['scenario'] = scenario;
      }

      final response = await dio.get(
        _baseUrl,
        queryParameters: queryParams,
        options: Options(
          headers: {
            'ngrok-skip-browser-warning': 'true',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final dynamic rawData = response.data;
        List<dynamic> itemsList = [];

        if (rawData is Map<String, dynamic> && rawData.containsKey('data')) {
          itemsList = rawData['data'] as List<dynamic>;
        } else if (rawData is List<dynamic>) {
          itemsList = rawData;
        }

        return itemsList
            .map((json) => ProductDto.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load products: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('API Request Failed: $e');
    }
  }
}
