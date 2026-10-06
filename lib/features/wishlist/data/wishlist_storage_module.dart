import 'package:injectable/injectable.dart';

import '../domain/repositories/i_wishlist_repository.dart';
import 'repositories/shared_preferences_wishlist_repository.dart';

/// Registers one [IWishlistRepository] per Data Source, each under its own
/// storage key, so `WishlistBloc` never needs to know which one is active.
@module
abstract class WishlistStorageModule {
  /// Live API (`dev` and `prod`).
  @Environment(Environment.dev)
  @Environment(Environment.prod)
  @lazySingleton
  IWishlistRepository get liveWishlistRepository =>
      const SharedPreferencesWishlistRepository(
        storageKey: 'wishlist_entries_live',
      );

  /// Mock Data.
  @Environment('mock')
  @lazySingleton
  IWishlistRepository get mockWishlistRepository =>
      const SharedPreferencesWishlistRepository(
        storageKey: 'wishlist_entries_mock',
      );
}
