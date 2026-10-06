import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:product_cart_app/core/error/failure.dart';
import 'package:product_cart_app/features/products/domain/entities/product.dart';
import 'package:product_cart_app/features/wishlist/domain/entities/wishlist_entry.dart';
import 'package:product_cart_app/features/wishlist/presentation/bloc/wishlist_bloc.dart';
import 'package:product_cart_app/features/wishlist/presentation/bloc/wishlist_event.dart';
import 'package:product_cart_app/features/wishlist/presentation/bloc/wishlist_state.dart';

import '../fakes/fake_product_repository.dart';
import '../fakes/fake_wishlist_repository.dart';

void main() {
  const headphones = Product(
    id: 'mock-1',
    name: 'Headphones',
    description: 'Noise cancelling',
    price: 199.99,
    imageUrl: 'https://example.com/1.png',
    stockQuantity: 5,
  );

  const soldOutWatch = Product(
    id: 'mock-3',
    name: 'Watch',
    description: 'Smart watch',
    price: 89.5,
    imageUrl: 'https://example.com/3.png',
    stockQuantity: 0,
    isOutOfStock: true,
  );

  final savedHeadphones = WishlistEntry(
    product: headphones,
    wishlistedPrice: 199.99,
    wishlistedAt: DateTime(2026, 10, 1),
  );

  late FakeWishlistRepository repository;
  late FakeProductRepository products;

  setUp(() {
    repository = FakeWishlistRepository();
    products = FakeProductRepository();
  });

  group('on start', () {
    blocTest<WishlistBloc, WishlistState>(
      'loads the saved Wishlist',
      setUp: () => repository = FakeWishlistRepository([savedHeadphones]),
      build: () => WishlistBloc(
        wishlistRepository: repository,
        productRepository: products,
      ),
      expect: () => [
        WishlistLoaded([savedHeadphones]),
      ],
    );
  });

  group('Toggle', () {
    final now = DateTime(2026, 10, 6, 9, 15);

    blocTest<WishlistBloc, WishlistState>(
      'Wishlists a Product with its current price and the current time',
      build: () => WishlistBloc(
        wishlistRepository: repository,
        productRepository: products,
        clock: () => now,
      ),
      act: (bloc) => bloc.add(const WishlistToggled(headphones)),
      expect: () => [
        const WishlistLoaded([]),
        WishlistLoaded([
          WishlistEntry(
            product: headphones,
            wishlistedPrice: 199.99,
            wishlistedAt: now,
          ),
        ]),
      ],
    );

    blocTest<WishlistBloc, WishlistState>(
      'takes a Wishlisted Product off the Wishlist',
      setUp: () => repository = FakeWishlistRepository([savedHeadphones]),
      build: () => WishlistBloc(
        wishlistRepository: repository,
        productRepository: products,
      ),
      act: (bloc) => bloc.add(const WishlistToggled(headphones)),
      expect: () => [
        WishlistLoaded([savedHeadphones]),
        const WishlistLoaded([]),
      ],
    );

    blocTest<WishlistBloc, WishlistState>(
      'recognises a Wishlisted Product by id even if its details changed',
      setUp: () => repository = FakeWishlistRepository([savedHeadphones]),
      build: () => WishlistBloc(
        wishlistRepository: repository,
        productRepository: products,
      ),
      act: (bloc) =>
          bloc.add(WishlistToggled(headphones.copyWith(price: 179.99))),
      skip: 1,
      expect: () => [const WishlistLoaded([])],
    );

    blocTest<WishlistBloc, WishlistState>(
      'sent while the saved Wishlist is still loading, applies after it loads',
      setUp: () => repository = FakeWishlistRepository([savedHeadphones]),
      build: () => WishlistBloc(
        wishlistRepository: repository,
        productRepository: products,
        clock: () => now,
      ),
      act: (bloc) => bloc.add(const WishlistToggled(soldOutWatch)),
      expect: () => [
        WishlistLoaded([savedHeadphones]),
        WishlistLoaded([
          WishlistEntry(
            product: soldOutWatch,
            wishlistedPrice: 89.5,
            wishlistedAt: now,
          ),
          savedHeadphones,
        ]),
      ],
    );

    blocTest<WishlistBloc, WishlistState>(
      'Wishlists an Out of Stock Product',
      build: () => WishlistBloc(
        wishlistRepository: repository,
        productRepository: products,
        clock: () => now,
      ),
      act: (bloc) => bloc.add(const WishlistToggled(soldOutWatch)),
      skip: 1,
      expect: () => [
        WishlistLoaded([
          WishlistEntry(
            product: soldOutWatch,
            wishlistedPrice: 89.5,
            wishlistedAt: now,
          ),
        ]),
      ],
    );
  });

  group('Remove', () {
    final savedWatch = WishlistEntry(
      product: soldOutWatch,
      wishlistedPrice: 99.0,
      wishlistedAt: DateTime(2026, 10, 3),
    );

    blocTest<WishlistBloc, WishlistState>(
      'takes the entry with that product id off the Wishlist and saves it',
      setUp: () =>
          repository = FakeWishlistRepository([savedWatch, savedHeadphones]),
      build: () => WishlistBloc(
        wishlistRepository: repository,
        productRepository: products,
      ),
      act: (bloc) => bloc.add(const WishlistEntryRemoved('mock-3')),
      expect: () => [
        WishlistLoaded([savedWatch, savedHeadphones]),
        WishlistLoaded([
          savedHeadphones,
        ], outcome: RemovedOutcome(savedWatch)),
      ],
      verify: (_) => expect(repository.saved, [savedHeadphones]),
    );

    blocTest<WishlistBloc, WishlistState>(
      'reports no removal when saving fails, so no Undo is offered',
      setUp: () => repository = FakeWishlistRepository([savedHeadphones]),
      build: () => WishlistBloc(
        wishlistRepository: repository,
        productRepository: products,
      ),
      act: (bloc) async {
        await bloc.stream.first;
        repository.failWith = const StorageFailure('disk full');
        bloc.add(const WishlistEntryRemoved('mock-1'));
      },
      expect: () => [
        WishlistLoaded([savedHeadphones]),
      ],
    );
  });

  group('Undo', () {
    const speaker = Product(
      id: 'mock-4',
      name: 'Speaker',
      description: 'Bluetooth speaker',
      price: 59.99,
      imageUrl: 'https://example.com/4.png',
      stockQuantity: 3,
    );
    final savedSpeaker = WishlistEntry(
      product: speaker,
      wishlistedPrice: 59.99,
      wishlistedAt: DateTime(2026, 10, 5),
    );
    // Its baseline differs from the current price, so a restore that
    // re-Wishlisted it from scratch would show up.
    final savedWatch = WishlistEntry(
      product: soldOutWatch,
      wishlistedPrice: 99.0,
      wishlistedAt: DateTime(2026, 10, 3),
    );

    blocTest<WishlistBloc, WishlistState>(
      'puts the removed entry back exactly as it was, in its original '
      'position, and saves it',
      setUp: () => repository = FakeWishlistRepository([
        savedSpeaker,
        savedWatch,
        savedHeadphones,
      ]),
      build: () => WishlistBloc(
        wishlistRepository: repository,
        productRepository: products,
      ),
      act: (bloc) => bloc
        ..add(const WishlistEntryRemoved('mock-3'))
        ..add(const WishlistRemovalUndone()),
      skip: 2,
      expect: () => [
        WishlistLoaded([savedSpeaker, savedWatch, savedHeadphones]),
      ],
      verify: (_) =>
          expect(repository.saved, [savedSpeaker, savedWatch, savedHeadphones]),
    );

    blocTest<WishlistBloc, WishlistState>(
      'restores only the most recently removed entry',
      setUp: () => repository = FakeWishlistRepository([
        savedSpeaker,
        savedWatch,
        savedHeadphones,
      ]),
      build: () => WishlistBloc(
        wishlistRepository: repository,
        productRepository: products,
      ),
      act: (bloc) => bloc
        ..add(const WishlistEntryRemoved('mock-4'))
        ..add(const WishlistEntryRemoved('mock-1'))
        ..add(const WishlistRemovalUndone())
        ..add(const WishlistRemovalUndone()),
      skip: 3,
      expect: () => [
        WishlistLoaded([savedWatch, savedHeadphones]),
      ],
    );

    blocTest<WishlistBloc, WishlistState>(
      'does not add a second entry if the Product was Wishlisted again '
      'before Undo',
      setUp: () => repository = FakeWishlistRepository([savedWatch]),
      build: () => WishlistBloc(
        wishlistRepository: repository,
        productRepository: products,
        clock: () => DateTime(2026, 10, 6),
      ),
      act: (bloc) => bloc
        ..add(const WishlistEntryRemoved('mock-3'))
        ..add(const WishlistToggled(soldOutWatch))
        ..add(const WishlistRemovalUndone()),
      verify: (bloc) => expect(
        bloc.state,
        WishlistLoaded([
          WishlistEntry(
            product: soldOutWatch,
            wishlistedPrice: 89.5,
            wishlistedAt: DateTime(2026, 10, 6),
          ),
        ]),
      ),
    );
  });

  group('state', () {
    final times = [DateTime(2026, 10, 6, 9), DateTime(2026, 10, 6, 10)];

    blocTest<WishlistBloc, WishlistState>(
      'lists the most recently Wishlisted first, with a count and an '
      'is-Wishlisted lookup',
      build: () {
        final clock = times.iterator;
        return WishlistBloc(
          wishlistRepository: repository,
          productRepository: products,
          clock: () => (clock..moveNext()).current,
        );
      },
      act: (bloc) => bloc
        ..add(const WishlistToggled(headphones))
        ..add(const WishlistToggled(soldOutWatch)),
      verify: (bloc) {
        final state = bloc.state as WishlistLoaded;
        expect(state.entries.map((e) => e.productId), ['mock-3', 'mock-1']);
        expect(state.count, 2);
        expect(state.isWishlisted('mock-1'), isTrue);
        expect(state.isWishlisted('mock-3'), isTrue);
        expect(state.isWishlisted('mock-2'), isFalse);
      },
    );

    blocTest<WishlistBloc, WishlistState>(
      'has a count of zero when nothing is Wishlisted',
      build: () => WishlistBloc(
        wishlistRepository: repository,
        productRepository: products,
      ),
      verify: (bloc) => expect((bloc.state as WishlistLoaded).count, 0),
    );
  });

  group('saving', () {
    final now = DateTime(2026, 10, 6, 9, 15);

    blocTest<WishlistBloc, WishlistState>(
      'saves the Wishlist after a Product is Wishlisted',
      build: () => WishlistBloc(
        wishlistRepository: repository,
        productRepository: products,
        clock: () => now,
      ),
      act: (bloc) => bloc.add(const WishlistToggled(soldOutWatch)),
      verify: (_) => expect(repository.saved, [
        WishlistEntry(
          product: soldOutWatch,
          wishlistedPrice: 89.5,
          wishlistedAt: now,
        ),
      ]),
    );

    blocTest<WishlistBloc, WishlistState>(
      'saves the Wishlist after a Product is taken off it',
      setUp: () => repository = FakeWishlistRepository([savedHeadphones]),
      build: () => WishlistBloc(
        wishlistRepository: repository,
        productRepository: products,
      ),
      act: (bloc) => bloc.add(const WishlistToggled(headphones)),
      verify: (_) => expect(repository.saved, isEmpty),
    );

    blocTest<WishlistBloc, WishlistState>(
      'a new WishlistBloc on the same storage starts with the same entries',
      setUp: () async {
        // A first app session Wishlists a Product, then the app is closed.
        final firstSession = WishlistBloc(
          wishlistRepository: repository,
          productRepository: products,
          clock: () => now,
        )..add(const WishlistToggled(headphones));
        await firstSession.stream.firstWhere(
          (state) => state is WishlistLoaded && state.count == 1,
        );
        await firstSession.close();
      },
      build: () => WishlistBloc(
        wishlistRepository: repository,
        productRepository: products,
      ),
      expect: () => [
        WishlistLoaded([
          WishlistEntry(
            product: headphones,
            wishlistedPrice: 199.99,
            wishlistedAt: now,
          ),
        ]),
      ],
    );

    blocTest<WishlistBloc, WishlistState>(
      'keeps the Wishlist unchanged when saving fails',
      setUp: () => repository = FakeWishlistRepository([savedHeadphones]),
      build: () => WishlistBloc(
        wishlistRepository: repository,
        productRepository: products,
      ),
      act: (bloc) async {
        await bloc.stream.first;
        repository.failWith = const StorageFailure('disk full');
        bloc.add(const WishlistToggled(soldOutWatch));
      },
      expect: () => [
        WishlistLoaded([savedHeadphones]),
      ],
    );

    blocTest<WishlistBloc, WishlistState>(
      'starts with an empty Wishlist when loading fails',
      setUp: () =>
          repository = FakeWishlistRepository([savedHeadphones])
            ..failWith = const StorageFailure('unreadable'),
      build: () => WishlistBloc(
        wishlistRepository: repository,
        productRepository: products,
      ),
      expect: () => [const WishlistLoaded([])],
    );
  });

  group('Repositories switched', () {
    final savedWatch = WishlistEntry(
      product: soldOutWatch,
      wishlistedPrice: 89.5,
      wishlistedAt: DateTime(2026, 10, 2),
    );

    late FakeWishlistRepository otherRepository;
    late FakeProductRepository otherProducts;

    setUp(() {
      otherRepository = FakeWishlistRepository([savedWatch]);
      otherProducts = FakeProductRepository();
    });

    blocTest<WishlistBloc, WishlistState>(
      "shows the new Data Source's Wishlist",
      setUp: () => repository = FakeWishlistRepository([savedHeadphones]),
      build: () => WishlistBloc(
        wishlistRepository: repository,
        productRepository: products,
      ),
      act: (bloc) => bloc.add(
        WishlistRepositoriesSwitched(
          wishlistRepository: otherRepository,
          productRepository: otherProducts,
        ),
      ),
      expect: () => [
        WishlistLoaded([savedHeadphones]),
        const WishlistLoading(),
        WishlistLoaded([savedWatch]),
      ],
    );

    blocTest<WishlistBloc, WishlistState>(
      "follows the new Data Source's catalog and stops following the old one",
      build: () => WishlistBloc(
        wishlistRepository: repository,
        productRepository: products,
      ),
      act: (bloc) async {
        expect(products.hasListener, isTrue);
        bloc.add(
          WishlistRepositoriesSwitched(
            wishlistRepository: otherRepository,
            productRepository: otherProducts,
          ),
        );
        await bloc.stream.firstWhere(
          (state) => state == WishlistLoaded([savedWatch]),
        );
        // Checked while the bloc is still open: blocTest closes it before
        // verify, which cancels every subscription.
        expect(products.hasListener, isFalse);
        expect(otherProducts.hasListener, isTrue);
      },
    );

    blocTest<WishlistBloc, WishlistState>(
      'stops following the catalog when closed',
      build: () => WishlistBloc(
        wishlistRepository: repository,
        productRepository: products,
      ),
      verify: (_) => expect(products.hasListener, isFalse),
    );

    blocTest<WishlistBloc, WishlistState>(
      "Undo does not bring an entry from the old Data Source's Wishlist "
      'into the new one',
      setUp: () => repository = FakeWishlistRepository([savedHeadphones]),
      build: () => WishlistBloc(
        wishlistRepository: repository,
        productRepository: products,
      ),
      act: (bloc) => bloc
        ..add(const WishlistEntryRemoved('mock-1'))
        ..add(
          WishlistRepositoriesSwitched(
            wishlistRepository: otherRepository,
            productRepository: otherProducts,
          ),
        )
        ..add(const WishlistRemovalUndone()),
      verify: (bloc) {
        expect(bloc.state, WishlistLoaded([savedWatch]));
        expect(otherRepository.saved, [savedWatch]);
      },
    );

    blocTest<WishlistBloc, WishlistState>(
      "saves changes to the new Data Source's Wishlist only",
      setUp: () => repository = FakeWishlistRepository([savedHeadphones]),
      build: () => WishlistBloc(
        wishlistRepository: repository,
        productRepository: products,
      ),
      act: (bloc) => bloc
        ..add(
          WishlistRepositoriesSwitched(
            wishlistRepository: otherRepository,
            productRepository: otherProducts,
          ),
        )
        ..add(const WishlistToggled(soldOutWatch)),
      verify: (_) {
        expect(otherRepository.saved, isEmpty);
        expect(repository.saved, [savedHeadphones]);
      },
    );
  });

  group('catalog updates', () {
    final cheaperHeadphones = headphones.copyWith(
      name: 'Headphones Pro',
      price: 179.99,
      imageUrl: 'https://example.com/1b.png',
      stockQuantity: 2,
    );
    final refreshedHeadphones = WishlistEntry(
      product: cheaperHeadphones,
      wishlistedPrice: 199.99,
      wishlistedAt: DateTime(2026, 10, 1),
    );

    blocTest<WishlistBloc, WishlistState>(
      'refresh and save the details of Wishlisted Products in the catalog, '
      'keeping the baseline',
      setUp: () => repository = FakeWishlistRepository([savedHeadphones]),
      build: () => WishlistBloc(
        wishlistRepository: repository,
        productRepository: products,
      ),
      act: (bloc) async {
        await bloc.stream.first;
        products.publish([cheaperHeadphones, soldOutWatch]);
      },
      verify: (bloc) {
        expect((bloc.state as WishlistLoaded).entries, [refreshedHeadphones]);
        expect(repository.saved, [refreshedHeadphones]);
      },
    );
  });

  group('Price Drop', () {
    WishlistEntry onlyEntry(WishlistBloc bloc) =>
        (bloc.state as WishlistLoaded).entries.single;

    Future<void> publishAfterLoad(WishlistBloc bloc, double price) async {
      await bloc.stream.first;
      products.publish([headphones.copyWith(price: price)]);
      // An unchanged price emits no new state, so let the update run out.
      await Future<void>.delayed(Duration.zero);
    }

    blocTest<WishlistBloc, WishlistState>(
      'is shown when the price falls below the price when Wishlisted',
      setUp: () => repository = FakeWishlistRepository([savedHeadphones]),
      build: () => WishlistBloc(
        wishlistRepository: repository,
        productRepository: products,
      ),
      act: (bloc) => publishAfterLoad(bloc, 179.99),
      verify: (bloc) => expect(onlyEntry(bloc).hasPriceDrop, isTrue),
    );

    for (final (label, price) in [('the same', 199.99), ('higher', 219.99)]) {
      blocTest<WishlistBloc, WishlistState>(
        'is not shown when the price is $label',
        setUp: () => repository = FakeWishlistRepository([savedHeadphones]),
        build: () => WishlistBloc(
          wishlistRepository: repository,
          productRepository: products,
        ),
        act: (bloc) => publishAfterLoad(bloc, price),
        verify: (bloc) => expect(onlyEntry(bloc).hasPriceDrop, isFalse),
      );
    }

    blocTest<WishlistBloc, WishlistState>(
      'starts over when the Product is removed and Wishlisted again',
      setUp: () => repository = FakeWishlistRepository([savedHeadphones]),
      build: () => WishlistBloc(
        wishlistRepository: repository,
        productRepository: products,
      ),
      act: (bloc) async {
        await publishAfterLoad(bloc, 179.99);
        final cheaper = onlyEntry(bloc).product;
        bloc
          ..add(WishlistToggled(cheaper))
          ..add(WishlistToggled(cheaper));
      },
      verify: (bloc) {
        expect(onlyEntry(bloc).wishlistedPrice, 179.99);
        expect(onlyEntry(bloc).hasPriceDrop, isFalse);
      },
    );
  });

  group('Out of Stock', () {
    WishlistLoaded loaded(WishlistBloc bloc) => bloc.state as WishlistLoaded;

    blocTest<WishlistBloc, WishlistState>(
      'follows the latest known details',
      setUp: () => repository = FakeWishlistRepository([savedHeadphones]),
      build: () => WishlistBloc(
        wishlistRepository: repository,
        productRepository: products,
      ),
      act: (bloc) async {
        await bloc.stream.first;
        expect(loaded(bloc).entries.single.isOutOfStock, isFalse);
        products.publish([
          headphones.copyWith(stockQuantity: 0, isOutOfStock: true),
        ]);
        await bloc.stream.first;
      },
      verify: (bloc) =>
          expect(loaded(bloc).entries.single.isOutOfStock, isTrue),
    );
  });

  group('No Longer Available', () {
    WishlistLoaded loaded(WishlistBloc bloc) => bloc.state as WishlistLoaded;

    final savedWatch = WishlistEntry(
      product: soldOutWatch,
      wishlistedPrice: 99.0,
      wishlistedAt: DateTime(2026, 10, 3),
    );

    Future<void> publishAfterLoad(
      WishlistBloc bloc,
      List<Product> catalog,
    ) async {
      await bloc.stream.first;
      products.publish(catalog);
      await bloc.stream.first;
    }

    blocTest<WishlistBloc, WishlistState>(
      'marks a Product missing from the latest catalog, keeping its entry '
      'and last-known details',
      setUp: () =>
          repository = FakeWishlistRepository([savedWatch, savedHeadphones]),
      build: () => WishlistBloc(
        wishlistRepository: repository,
        productRepository: products,
      ),
      act: (bloc) => publishAfterLoad(bloc, [soldOutWatch]),
      verify: (bloc) {
        expect(loaded(bloc).entries, [savedWatch, savedHeadphones]);
        expect(loaded(bloc).isNoLongerAvailable('mock-1'), isTrue);
        expect(loaded(bloc).isNoLongerAvailable('mock-3'), isFalse);
        expect(repository.saved, [savedWatch, savedHeadphones]);
      },
    );

    blocTest<WishlistBloc, WishlistState>(
      'is cleared when the Product comes back to the catalog',
      setUp: () => repository = FakeWishlistRepository([savedHeadphones]),
      build: () => WishlistBloc(
        wishlistRepository: repository,
        productRepository: products,
      ),
      act: (bloc) async {
        await publishAfterLoad(bloc, []);
        expect(loaded(bloc).isNoLongerAvailable('mock-1'), isTrue);
        products.publish([headphones]);
        await bloc.stream.first;
      },
      verify: (bloc) {
        expect(loaded(bloc).entries, [savedHeadphones]);
        expect(loaded(bloc).isNoLongerAvailable('mock-1'), isFalse);
      },
    );

    blocTest<WishlistBloc, WishlistState>(
      'is still marked when saving the refreshed details fails, which keep '
      'their saved values',
      setUp: () =>
          repository = FakeWishlistRepository([savedWatch, savedHeadphones]),
      build: () => WishlistBloc(
        wishlistRepository: repository,
        productRepository: products,
      ),
      act: (bloc) async {
        await bloc.stream.first;
        repository.failWith = const StorageFailure('disk full');
        products.publish([soldOutWatch.copyWith(price: 79.0)]);
        await bloc.stream.first;
      },
      verify: (bloc) {
        expect(loaded(bloc).entries, [savedWatch, savedHeadphones]);
        expect(loaded(bloc).isNoLongerAvailable('mock-1'), isTrue);
        expect(loaded(bloc).isNoLongerAvailable('mock-3'), isFalse);
      },
    );

    blocTest<WishlistBloc, WishlistState>(
      'marks every entry when the catalog is empty',
      setUp: () =>
          repository = FakeWishlistRepository([savedWatch, savedHeadphones]),
      build: () => WishlistBloc(
        wishlistRepository: repository,
        productRepository: products,
      ),
      act: (bloc) => publishAfterLoad(bloc, []),
      verify: (bloc) {
        expect(loaded(bloc).entries, [savedWatch, savedHeadphones]);
        expect(loaded(bloc).isNoLongerAvailable('mock-1'), isTrue);
        expect(loaded(bloc).isNoLongerAvailable('mock-3'), isTrue);
      },
    );

    blocTest<WishlistBloc, WishlistState>(
      'marks nothing before the first catalog arrives',
      setUp: () => repository = FakeWishlistRepository([savedHeadphones]),
      build: () => WishlistBloc(
        wishlistRepository: repository,
        productRepository: products,
      ),
      verify: (bloc) =>
          expect(loaded(bloc).isNoLongerAvailable('mock-1'), isFalse),
    );

    blocTest<WishlistBloc, WishlistState>(
      'marks nothing once the Data Source is switched, until the new '
      "catalog arrives",
      setUp: () => repository = FakeWishlistRepository([savedHeadphones]),
      build: () => WishlistBloc(
        wishlistRepository: repository,
        productRepository: products,
      ),
      act: (bloc) async {
        await publishAfterLoad(bloc, []);
        bloc.add(
          WishlistRepositoriesSwitched(
            wishlistRepository: FakeWishlistRepository([savedHeadphones]),
            productRepository: FakeProductRepository(),
          ),
        );
      },
      verify: (bloc) =>
          expect(loaded(bloc).isNoLongerAvailable('mock-1'), isFalse),
    );
  });

  group('Can Move to Cart', () {
    WishlistLoaded loaded(WishlistBloc bloc) => bloc.state as WishlistLoaded;

    blocTest<WishlistBloc, WishlistState>(
      'is true for an in-stock Product in the latest catalog',
      setUp: () => repository = FakeWishlistRepository([savedHeadphones]),
      build: () => WishlistBloc(
        wishlistRepository: repository,
        productRepository: products,
      ),
      act: (bloc) async {
        await bloc.stream.first;
        products.publish([headphones]);
        await bloc.stream.first;
      },
      verify: (bloc) => expect(loaded(bloc).canMoveToCart('mock-1'), isTrue),
    );

    blocTest<WishlistBloc, WishlistState>(
      'is false for an Out of Stock Product',
      setUp: () => repository = FakeWishlistRepository([
        WishlistEntry(
          product: soldOutWatch,
          wishlistedPrice: 89.5,
          wishlistedAt: DateTime(2026, 10, 3),
        ),
      ]),
      build: () => WishlistBloc(
        wishlistRepository: repository,
        productRepository: products,
      ),
      act: (bloc) async {
        await bloc.stream.first;
        products.publish([soldOutWatch]);
        await bloc.stream.first;
      },
      verify: (bloc) => expect(loaded(bloc).canMoveToCart('mock-3'), isFalse),
    );

    blocTest<WishlistBloc, WishlistState>(
      'is false for a No Longer Available Product, and true again once it '
      'comes back',
      setUp: () => repository = FakeWishlistRepository([savedHeadphones]),
      build: () => WishlistBloc(
        wishlistRepository: repository,
        productRepository: products,
      ),
      act: (bloc) async {
        await bloc.stream.first;
        products.publish([]);
        await bloc.stream.first;
        expect(loaded(bloc).canMoveToCart('mock-1'), isFalse);
        products.publish([headphones]);
        await bloc.stream.first;
      },
      verify: (bloc) => expect(loaded(bloc).canMoveToCart('mock-1'), isTrue),
    );

    blocTest<WishlistBloc, WishlistState>(
      'is true for an in-stock Product before the first catalog arrives',
      setUp: () => repository = FakeWishlistRepository([savedHeadphones]),
      build: () => WishlistBloc(
        wishlistRepository: repository,
        productRepository: products,
      ),
      verify: (bloc) => expect(loaded(bloc).canMoveToCart('mock-1'), isTrue),
    );
  });

  group('Move to Cart', () {
    final savedWatch = WishlistEntry(
      product: soldOutWatch,
      wishlistedPrice: 99.0,
      wishlistedAt: DateTime(2026, 10, 3),
    );

    blocTest<WishlistBloc, WishlistState>(
      'takes the entry off the Wishlist and saves it',
      setUp: () =>
          repository = FakeWishlistRepository([savedWatch, savedHeadphones]),
      build: () => WishlistBloc(
        wishlistRepository: repository,
        productRepository: products,
      ),
      act: (bloc) => bloc.add(const WishlistMovedToCart('mock-1')),
      expect: () => [
        WishlistLoaded([savedWatch, savedHeadphones]),
        WishlistLoaded([
          savedWatch,
        ], outcome: MovedToCartOutcome(savedHeadphones)),
      ],
      verify: (_) => expect(repository.saved, [savedWatch]),
    );

    blocTest<WishlistBloc, WishlistState>(
      'reports no move and keeps the entry when saving fails, so the screen '
      'does not add it to the Cart',
      setUp: () => repository = FakeWishlistRepository([savedHeadphones]),
      build: () => WishlistBloc(
        wishlistRepository: repository,
        productRepository: products,
      ),
      act: (bloc) async {
        await bloc.stream.first;
        repository.failWith = const StorageFailure('disk full');
        bloc.add(const WishlistMovedToCart('mock-1'));
      },
      expect: () => [
        WishlistLoaded([savedHeadphones]),
      ],
    );

    blocTest<WishlistBloc, WishlistState>(
      'cannot be undone: Undo restores the entry removed before it instead',
      setUp: () =>
          repository = FakeWishlistRepository([savedWatch, savedHeadphones]),
      build: () => WishlistBloc(
        wishlistRepository: repository,
        productRepository: products,
      ),
      act: (bloc) => bloc
        ..add(const WishlistEntryRemoved('mock-3'))
        ..add(const WishlistMovedToCart('mock-1'))
        ..add(const WishlistRemovalUndone()),
      verify: (bloc) {
        expect(bloc.state, WishlistLoaded([savedWatch]));
        expect(repository.saved, [savedWatch]);
      },
    );

    blocTest<WishlistBloc, WishlistState>(
      'leaves an Out of Stock entry on the Wishlist',
      setUp: () =>
          repository = FakeWishlistRepository([savedWatch, savedHeadphones]),
      build: () => WishlistBloc(
        wishlistRepository: repository,
        productRepository: products,
      ),
      act: (bloc) => bloc.add(const WishlistMovedToCart('mock-3')),
      expect: () => [
        WishlistLoaded([savedWatch, savedHeadphones]),
      ],
      verify: (_) => expect(repository.saved, [savedWatch, savedHeadphones]),
    );

    blocTest<WishlistBloc, WishlistState>(
      'leaves a No Longer Available entry on the Wishlist',
      setUp: () => repository = FakeWishlistRepository([savedHeadphones]),
      build: () => WishlistBloc(
        wishlistRepository: repository,
        productRepository: products,
      ),
      act: (bloc) async {
        await bloc.stream.first;
        products.publish([]);
        await bloc.stream.first;
        bloc.add(const WishlistMovedToCart('mock-1'));
      },
      verify: (bloc) {
        expect((bloc.state as WishlistLoaded).entries, [savedHeadphones]);
        expect(repository.saved, [savedHeadphones]);
      },
    );
  });
}
