import 'package:flutter_test/flutter_test.dart';
import 'package:injectable/injectable.dart' show Environment;
import 'package:product_cart_app/core/di/injection.dart';
import 'package:product_cart_app/features/products/domain/entities/product.dart';
import 'package:product_cart_app/features/wishlist/data/repositories/shared_preferences_wishlist_repository.dart';
import 'package:product_cart_app/features/wishlist/domain/entities/wishlist_entry.dart';
import 'package:product_cart_app/features/wishlist/domain/repositories/i_wishlist_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final headphones = WishlistEntry(
    product: const Product(
      id: 'mock-1',
      name: 'Headphones',
      description: 'Noise cancelling',
      price: 199.99,
      imageUrl: 'https://example.com/1.png',
      stockQuantity: 5,
    ),
    wishlistedPrice: 199.99,
    wishlistedAt: DateTime.utc(2026, 10, 6, 12, 30),
  );
  final soldOutWatch = WishlistEntry(
    product: const Product(
      id: 'mock-3',
      name: 'Watch',
      description: 'Smart watch',
      price: 89.5,
      imageUrl: 'https://example.com/3.png',
      stockQuantity: 0,
      isOutOfStock: true,
    ),
    wishlistedPrice: 99,
    wishlistedAt: DateTime.utc(2026, 10, 5, 8),
  );

  const key = 'wishlist_test';

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('saved entries load back unchanged', () async {
    final repository = SharedPreferencesWishlistRepository(storageKey: key);

    await repository.saveEntries([headphones, soldOutWatch]).run();
    final loaded = await repository.loadEntries().run();

    expect(loaded.getRight().toNullable(), [headphones, soldOutWatch]);
  });

  test('saving replaces what was saved before', () async {
    final repository = SharedPreferencesWishlistRepository(storageKey: key);

    await repository.saveEntries([headphones, soldOutWatch]).run();
    await repository.saveEntries([soldOutWatch]).run();
    final loaded = await repository.loadEntries().run();

    expect(loaded.getRight().toNullable(), [soldOutWatch]);
  });

  test('a device with nothing saved loads an empty Wishlist', () async {
    final loaded = await SharedPreferencesWishlistRepository(
      storageKey: key,
    ).loadEntries().run();

    expect(loaded.getRight().toNullable(), isEmpty);
  });

  group('corrupt data loads as an empty Wishlist', () {
    final corruptValues = {
      'not JSON': 'this is {not json',
      'JSON that is not a list': '{"product": {}}',
      'an entry with missing fields': '[{"wishlistedPrice": 10}]',
      'an entry with wrong types':
          '[{"product": {"id": 1}, "wishlistedPrice": "cheap", '
          '"wishlistedAt": "yesterday"}]',
      'an unparseable date':
          '[{"product": {"id": "mock-1", "name": "n", "description": "d", '
          '"price": 1, "imageUrl": "u", "stockQuantity": 1, '
          '"isOutOfStock": false}, "wishlistedPrice": 1, '
          '"wishlistedAt": "not a date"}]',
    };

    corruptValues.forEach((description, raw) {
      test(description, () async {
        SharedPreferences.setMockInitialValues({key: raw});

        final loaded = await SharedPreferencesWishlistRepository(
          storageKey: key,
        ).loadEntries().run();

        expect(loaded.getRight().toNullable(), isEmpty);
      });
    });

    test('a value stored with the wrong type', () async {
      SharedPreferences.setMockInitialValues({key: 42});

      final loaded = await SharedPreferencesWishlistRepository(
        storageKey: key,
      ).loadEntries().run();

      expect(loaded.getRight().toNullable(), isEmpty);
    });
  });

  test('saving under one storage key leaves the other unchanged', () async {
    final mockWishlist = SharedPreferencesWishlistRepository(
      storageKey: 'wishlist_a',
    );
    final liveWishlist = SharedPreferencesWishlistRepository(
      storageKey: 'wishlist_b',
    );
    await liveWishlist.saveEntries([soldOutWatch]).run();

    await mockWishlist.saveEntries([headphones]).run();

    expect((await liveWishlist.loadEntries().run()).getRight().toNullable(), [
      soldOutWatch,
    ]);
    expect((await mockWishlist.loadEntries().run()).getRight().toNullable(), [
      headphones,
    ]);
  });

  group('each Data Source has its own Wishlist', () {
    tearDown(() => getIt.reset());

    Future<IWishlistRepository> wishlistFor(String environment) async {
      await getIt.reset();
      configureDependencies(environment: environment);
      return getIt<IWishlistRepository>();
    }

    test('saving under Mock Data leaves the Live Wishlist unchanged', () async {
      await (await wishlistFor(
        Environment.dev,
      )).saveEntries([soldOutWatch]).run();

      await (await wishlistFor('mock')).saveEntries([headphones]).run();

      final live = await (await wishlistFor(
        Environment.dev,
      )).loadEntries().run();
      final mock = await (await wishlistFor('mock')).loadEntries().run();
      expect(live.getRight().toNullable(), [soldOutWatch]);
      expect(mock.getRight().toNullable(), [headphones]);
    });

    test(
      'prod uses the same Wishlist as dev (both are the Live API)',
      () async {
        await (await wishlistFor(
          Environment.dev,
        )).saveEntries([headphones]).run();

        final prod = await (await wishlistFor(
          Environment.prod,
        )).loadEntries().run();

        expect(prod.getRight().toNullable(), [headphones]);
      },
    );
  });
}
