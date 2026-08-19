// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i361;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../../features/cart/presentation/bloc/cart_bloc.dart' as _i517;
import '../../features/products/data/datasources/mock_product_remote_data_source_impl.dart'
    as _i582;
import '../../features/products/data/datasources/product_remote_data_source.dart'
    as _i166;
import '../../features/products/data/datasources/product_remote_data_source_impl.dart'
    as _i818;
import '../../features/products/data/repositories/product_repository_impl.dart'
    as _i764;
import '../../features/products/domain/repositories/i_product_repository.dart'
    as _i367;
import '../../features/products/presentation/bloc/product_list_bloc.dart'
    as _i848;
import '../network/dio_client.dart' as _i667;
import 'register_module.dart' as _i291;

const String _dev = 'dev';
const String _prod = 'prod';
const String _mock = 'mock';

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    gh.lazySingleton<_i361.Dio>(() => registerModule.dio);
    gh.lazySingleton<_i667.DioClient>(() => _i667.DioClient());
    gh.lazySingleton<_i166.IProductRemoteDataSource>(
      () => _i818.ProductRemoteDataSourceImpl(dio: gh<_i361.Dio>()),
      registerFor: {_dev, _prod},
    );
    gh.lazySingleton<_i166.IProductRemoteDataSource>(
      () => _i582.MockProductRemoteDataSourceImpl(),
      registerFor: {_mock},
    );
    gh.factory<_i367.IProductRepository>(
      () => _i764.ProductRepositoryImpl(
        remoteDataSource: gh<_i166.IProductRemoteDataSource>(),
      ),
    );
    gh.factory<_i517.CartBloc>(
      () => _i517.CartBloc(productRepository: gh<_i367.IProductRepository>()),
    );
    gh.factory<_i848.ProductListBloc>(
      () => _i848.ProductListBloc(
        productRepository: gh<_i367.IProductRepository>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}
