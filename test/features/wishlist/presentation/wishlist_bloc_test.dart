import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:product_cart_app/core/error/failure.dart';
import 'package:product_cart_app/features/products/domain/entities/product.dart';
import 'package:product_cart_app/features/wishlist/domain/entities/wishlist_entry.dart';
import 'package:product_cart_app/features/wishlist/presentation/bloc/wishlist_bloc.dart';
import 'package:product_cart_app/features/wishlist/presentation/bloc/wishlist_event.dart';
import 'package:product_cart_app/features/wishlist/presentation/bloc/wishlist_state.dart';

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

  setUp(() => repository = FakeWishlistRepository());

  group('on start', () {
    blocTest<WishlistBloc, WishlistState>(
      'loads the saved Wishlist',
      setUp: () => repository = FakeWishlistRepository([savedHeadphones]),
      build: () => WishlistBloc(wishlistRepository: repository),
      expect: () => [
        WishlistLoaded([savedHeadphones]),
      ],
    );
  });

  group('Toggle', () {
    final now = DateTime(2026, 10, 6, 9, 15);

    blocTest<WishlistBloc, WishlistState>(
      'Wishlists a Product with its current price and the current time',
      build: () =>
          WishlistBloc(wishlistRepository: repository, clock: () => now),
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
      build: () => WishlistBloc(wishlistRepository: repository),
      act: (bloc) => bloc.add(const WishlistToggled(headphones)),
      expect: () => [
        WishlistLoaded([savedHeadphones]),
        const WishlistLoaded([]),
      ],
    );

    blocTest<WishlistBloc, WishlistState>(
      'recognises a Wishlisted Product by id even if its details changed',
      setUp: () => repository = FakeWishlistRepository([savedHeadphones]),
      build: () => WishlistBloc(wishlistRepository: repository),
      act: (bloc) =>
          bloc.add(WishlistToggled(headphones.copyWith(price: 179.99))),
      skip: 1,
      expect: () => [const WishlistLoaded([])],
    );

    blocTest<WishlistBloc, WishlistState>(
      'sent while the saved Wishlist is still loading, applies after it loads',
      setUp: () => repository = FakeWishlistRepository([savedHeadphones]),
      build: () =>
          WishlistBloc(wishlistRepository: repository, clock: () => now),
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
      build: () =>
          WishlistBloc(wishlistRepository: repository, clock: () => now),
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
      build: () => WishlistBloc(wishlistRepository: repository),
      act: (bloc) => bloc.add(const WishlistEntryRemoved('mock-3')),
      expect: () => [
        WishlistLoaded([savedWatch, savedHeadphones]),
        WishlistLoaded([savedHeadphones]),
      ],
      verify: (_) => expect(repository.saved, [savedHeadphones]),
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
      build: () => WishlistBloc(wishlistRepository: repository),
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
      build: () => WishlistBloc(wishlistRepository: repository),
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
      build: () => WishlistBloc(wishlistRepository: repository),
      verify: (bloc) => expect((bloc.state as WishlistLoaded).count, 0),
    );
  });

  group('saving', () {
    final now = DateTime(2026, 10, 6, 9, 15);

    blocTest<WishlistBloc, WishlistState>(
      'saves the Wishlist after a Product is Wishlisted',
      build: () =>
          WishlistBloc(wishlistRepository: repository, clock: () => now),
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
      build: () => WishlistBloc(wishlistRepository: repository),
      act: (bloc) => bloc.add(const WishlistToggled(headphones)),
      verify: (_) => expect(repository.saved, isEmpty),
    );

    blocTest<WishlistBloc, WishlistState>(
      'a new WishlistBloc on the same storage starts with the same entries',
      setUp: () async {
        // A first app session Wishlists a Product, then the app is closed.
        final firstSession = WishlistBloc(
          wishlistRepository: repository,
          clock: () => now,
        )..add(const WishlistToggled(headphones));
        await firstSession.stream.firstWhere(
          (state) => state is WishlistLoaded && state.count == 1,
        );
        await firstSession.close();
      },
      build: () => WishlistBloc(wishlistRepository: repository),
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
      build: () => WishlistBloc(wishlistRepository: repository),
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
      build: () => WishlistBloc(wishlistRepository: repository),
      expect: () => [const WishlistLoaded([])],
    );
  });
}
