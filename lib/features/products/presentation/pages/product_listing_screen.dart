import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/di/injection.dart';
import '../../domain/repositories/i_product_repository.dart';
import '../bloc/product_list_bloc.dart';
import '../bloc/product_list_event.dart';
import '../bloc/product_list_state.dart';
import '../widgets/product_shimmer_list.dart';
import '../widgets/product_empty_view.dart';
import '../widgets/product_error_view.dart';
import '../widgets/product_tile.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../../../cart/presentation/bloc/cart_state.dart';
import '../../../cart/presentation/pages/cart_screen.dart';

class ProductListingScreen extends StatefulWidget {
  const ProductListingScreen({super.key});

  @override
  State<ProductListingScreen> createState() => _ProductListingScreenState();
}

class _ProductListingScreenState extends State<ProductListingScreen> {
  String?
  _selectedScenario; // null (normal), 'updated', 'error', 'slow', 'empty'
  bool _isMockMode = false;

  @override
  void initState() {
    super.initState();
    context.read<ProductListBloc>().add(const FetchProductsEvent());
  }

  Future<void> _toggleRepositoryMode(bool isMock) async {
    if (_isMockMode == isMock) return;
    setState(() {
      _isMockMode = isMock;
    });

    // Asynchronously reset GetIt to cleanly dispose & unregister all singletons
    await getIt.reset();
    configureDependencies(environment: isMock ? 'mock' : Environment.dev);

    if (!mounted) return;

    final newRepository = getIt<IProductRepository>();

    // Update BLoCs with the new repository instance
    context.read<ProductListBloc>().add(
      SwitchRepositoryEvent(
        newRepository: newRepository,
        scenario: _selectedScenario,
      ),
    );
    context.read<CartBloc>().updateRepository(newRepository);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isMock
              ? 'Switched to MOCK Repository (Local Mock Data)'
              : 'Switched to LIVE Repository (Remote API)',
        ),
        backgroundColor: isMock ? Colors.teal : Colors.deepPurple,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CartBloc, CartState>(
      listenWhen: (previous, current) =>
          current.notificationMessage != null &&
          current.notificationMessage != previous.notificationMessage,
      listener: (context, state) {
        if (state.notificationMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.notificationMessage!),
              backgroundColor: Colors.amber.shade900,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Product Catalog'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          actions: [
            PopupMenuButton<String?>(
              icon: const Icon(Icons.bug_report),
              tooltip: 'Select API Scenario',
              onSelected: (String? scenario) {
                setState(() {
                  _selectedScenario = scenario;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      scenario == null
                          ? 'Active Scenario: Normal'
                          : 'Active Scenario: ?scenario=$scenario',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
                // Trigger fetch with selected scenario
                context.read<ProductListBloc>().add(
                  FetchProductsEvent(scenario: scenario),
                );
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String?>>[
                PopupMenuItem<String?>(
                  value: 'normal',
                  child: Row(
                    children: [
                      Icon(
                        _selectedScenario == null ||
                                _selectedScenario == 'normal'
                            ? Icons.check
                            : Icons.circle_outlined,
                        size: 18,
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(width: 8),
                      const Text('Normal (Default)'),
                    ],
                  ),
                ),
                PopupMenuItem<String?>(
                  value: 'updated',
                  child: Row(
                    children: [
                      Icon(
                        _selectedScenario == 'updated'
                            ? Icons.check
                            : Icons.circle_outlined,
                        size: 18,
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(width: 8),
                      const Text('?scenario=updated'),
                    ],
                  ),
                ),
                PopupMenuItem<String?>(
                  value: 'error',
                  child: Row(
                    children: [
                      Icon(
                        _selectedScenario == 'error'
                            ? Icons.check
                            : Icons.circle_outlined,
                        size: 18,
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(width: 8),
                      const Text('?scenario=error'),
                    ],
                  ),
                ),
                PopupMenuItem<String?>(
                  value: 'slow',
                  child: Row(
                    children: [
                      Icon(
                        _selectedScenario == 'slow'
                            ? Icons.check
                            : Icons.circle_outlined,
                        size: 18,
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(width: 8),
                      const Text('?scenario=slow'),
                    ],
                  ),
                ),
                PopupMenuItem<String?>(
                  value: 'empty',
                  child: Row(
                    children: [
                      Icon(
                        _selectedScenario == 'empty'
                            ? Icons.check
                            : Icons.circle_outlined,
                        size: 18,
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(width: 8),
                      const Text('?scenario=empty'),
                    ],
                  ),
                ),
              ],
            ),
            BlocBuilder<CartBloc, CartState>(
              builder: (context, cartState) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: context.read<CartBloc>(),
                              child: const CartScreen(),
                            ),
                          ),
                        );
                      },
                    ),
                    if (cartState.itemCount > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: CircleAvatar(
                          radius: 9,
                          backgroundColor: Colors.red,
                          child: Text(
                            '${cartState.itemCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Data Source Banner Widget Above List
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _isMockMode
                    ? Colors.amber.shade50
                    : Colors.deepPurple.shade50,
                border: Border(
                  bottom: BorderSide(
                    color: _isMockMode
                        ? Colors.amber.shade200
                        : Colors.deepPurple.shade100,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isMockMode
                            ? Icons.data_object_rounded
                            : Icons.cloud_done_rounded,
                        size: 20,
                        color: _isMockMode
                            ? Colors.amber.shade900
                            : Colors.deepPurple.shade700,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Data Source:',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _isMockMode
                                ? 'Mock Data (Local)'
                                : 'Live API (Remote)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _isMockMode
                                  ? Colors.amber.shade900
                                  : Colors.deepPurple.shade800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Segmented Switch Widget
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isMockMode
                            ? Colors.amber.shade300
                            : Colors.deepPurple.shade200,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _toggleRepositoryMode(false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: !_isMockMode
                                  ? Colors.deepPurple
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Live API',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: !_isMockMode
                                    ? Colors.white
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _toggleRepositoryMode(true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _isMockMode
                                  ? Colors.amber
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Mock Data',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _isMockMode
                                    ? Colors.black
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Expanded List / State View
            Expanded(
              child: BlocBuilder<ProductListBloc, ProductListState>(
                builder: (context, state) {
                  if (state is ProductListLoadingState) {
                    return const ProductShimmerList();
                  } else if (state is ProductListEmptyState) {
                    return ProductEmptyView(
                      onRefresh: () {
                        context.read<ProductListBloc>().add(
                          FetchProductsEvent(scenario: _selectedScenario),
                        );
                      },
                    );
                  } else if (state is ProductListErrorState) {
                    return ProductErrorView(
                      errorMessage: state.errorMessage,
                      onRetry: () {
                        context.read<ProductListBloc>().add(
                          FetchProductsEvent(scenario: _selectedScenario),
                        );
                      },
                    );
                  } else if (state is ProductListLoadedState) {
                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<ProductListBloc>().add(
                          RefreshProductsEvent(scenario: _selectedScenario),
                        );
                      },
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: state.products.length,
                        itemBuilder: (context, index) {
                          final product = state.products[index];
                          return ProductTile(
                            product: product,
                            onAddToCart: () {
                              context.read<CartBloc>().add(
                                AddToCartEvent(product),
                              );
                            },
                          );
                        },
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
