import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection.dart';
import 'features/products/domain/repositories/i_product_repository.dart';
import 'features/products/presentation/bloc/product_list_bloc.dart';
import 'features/products/presentation/pages/product_listing_screen.dart';
import 'features/cart/presentation/bloc/cart_bloc.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure GetIt dependency injection for default environment ('dev')
  configureDependencies();

  final productRepository = getIt<IProductRepository>();

  runApp(ProductCartApp(productRepository: productRepository));
}

class ProductCartApp extends StatelessWidget {
  final IProductRepository productRepository;

  const ProductCartApp({super.key, required this.productRepository});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ProductListBloc>(
          create: (_) => ProductListBloc(productRepository: productRepository),
        ),
        BlocProvider<CartBloc>(
          create: (_) => CartBloc(productRepository: productRepository),
        ),
      ],
      child: MaterialApp(
        title: 'Product Cart Architecture',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.deepPurple,
        ),
        home: const ProductListingScreen(),
      ),
    );
  }
}
