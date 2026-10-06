import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../products/domain/entities/product.dart';
import '../../domain/entities/wishlist_entry.dart';
import '../../domain/repositories/i_wishlist_repository.dart';
import 'wishlist_event.dart';
import 'wishlist_state.dart';

class WishlistBloc extends Bloc<WishlistEvent, WishlistState> {
  final IWishlistRepository _wishlistRepository;
  final DateTime Function() _clock;

  WishlistBloc({
    required IWishlistRepository wishlistRepository,
    DateTime Function()? clock,
  }) : _wishlistRepository = wishlistRepository,
       _clock = clock ?? DateTime.now,
       super(const WishlistLoading()) {
    on<WishlistEvent>(
      (event, emit) => switch (event) {
        WishlistStarted() => _onStarted(emit),
        WishlistToggled(:final product) => _onToggled(product, emit),
      },
      transformer: sequential(),
    );
    add(const WishlistStarted());
  }

  Future<void> _onStarted(Emitter<WishlistState> emit) async {
    final result = await _wishlistRepository.loadEntries().run();
    emit(WishlistLoaded(result.getOrElse((_) => const [])));
  }

  Future<void> _onToggled(Product product, Emitter<WishlistState> emit) async {
    final current = state;
    if (current is! WishlistLoaded) return;

    final List<WishlistEntry> entries;
    if (current.isWishlisted(product.id)) {
      entries = [
        for (final entry in current.entries)
          if (entry.productId != product.id) entry,
      ];
    } else {
      final entry = WishlistEntry(
        product: product,
        wishlistedPrice: product.price,
        wishlistedAt: _clock(),
      );
      entries = [entry, ...current.entries];
    }
    await _save(entries, emit);
  }

  /// Saves [entries] and, once they are safely stored, emits them.
  /// If saving fails the Wishlist stays as it was, so the screen never shows
  /// a change that would be lost on restart.
  Future<void> _save(
    List<WishlistEntry> entries,
    Emitter<WishlistState> emit,
  ) async {
    final result = await _wishlistRepository.saveEntries(entries).run();
    if (result.isRight()) emit(WishlistLoaded(entries));
  }
}
