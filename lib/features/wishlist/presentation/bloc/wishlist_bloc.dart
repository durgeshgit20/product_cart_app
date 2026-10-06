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

  /// The entry most recently taken off by Remove, kept for Undo.
  WishlistEntry? _lastRemoved;

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
        WishlistEntryRemoved(:final productId) => _onRemoved(productId, emit),
        WishlistRemovalUndone() => _onRemovalUndone(emit),
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

  Future<void> _onRemoved(String productId, Emitter<WishlistState> emit) async {
    final current = state;
    if (current is! WishlistLoaded) return;
    final removed = current.entries
        .where((entry) => entry.productId == productId)
        .firstOrNull;
    if (removed == null) return;

    final saved = await _save([
      for (final entry in current.entries)
        if (entry.productId != productId) entry,
    ], emit);
    if (saved) _lastRemoved = removed;
  }

  Future<void> _onRemovalUndone(Emitter<WishlistState> emit) async {
    final current = state;
    final removed = _lastRemoved;
    if (current is! WishlistLoaded || removed == null) return;
    _lastRemoved = null;
    // Wishlisted again in the meantime: keep the newer entry.
    if (current.isWishlisted(removed.productId)) return;

    // Entries are newest first, so the removed one goes back before the
    // first entry Wishlisted earlier than it: its original position.
    final index = current.entries.indexWhere(
      (entry) => entry.wishlistedAt.isBefore(removed.wishlistedAt),
    );
    final entries = List.of(current.entries)
      ..insert(index == -1 ? current.entries.length : index, removed);
    if (!await _save(entries, emit)) _lastRemoved = removed;
  }

  /// Saves [entries] and, once they are safely stored, emits them.
  /// If saving fails the Wishlist stays as it was, so the screen never shows
  /// a change that would be lost on restart. Returns whether it was saved.
  Future<bool> _save(
    List<WishlistEntry> entries,
    Emitter<WishlistState> emit,
  ) async {
    final result = await _wishlistRepository.saveEntries(entries).run();
    if (result.isLeft()) return false;
    emit(WishlistLoaded(entries));
    return true;
  }
}
