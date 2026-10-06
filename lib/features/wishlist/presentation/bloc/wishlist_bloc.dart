import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../products/domain/entities/product.dart';
import '../../../products/domain/repositories/i_product_repository.dart';
import '../../domain/entities/wishlist_entry.dart';
import '../../domain/repositories/i_wishlist_repository.dart';
import 'wishlist_event.dart';
import 'wishlist_state.dart';

class WishlistBloc extends Bloc<WishlistEvent, WishlistState> {
  IWishlistRepository _wishlistRepository;
  IProductRepository _productRepository;
  StreamSubscription<List<Product>>? _catalogSubscription;
  final DateTime Function() _clock;

  /// The entry most recently taken off by Remove, kept for Undo.
  WishlistEntry? _lastRemoved;

  WishlistBloc({
    required IWishlistRepository wishlistRepository,
    required IProductRepository productRepository,
    DateTime Function()? clock,
  }) : _wishlistRepository = wishlistRepository,
       _productRepository = productRepository,
       _clock = clock ?? DateTime.now,
       super(const WishlistLoading()) {
    on<WishlistEvent>(
      (event, emit) => switch (event) {
        WishlistStarted() => _onStarted(emit),
        WishlistToggled(:final product) => _onToggled(product, emit),
        WishlistEntryRemoved(:final productId) => _onRemoved(productId, emit),
        WishlistMovedToCart(:final productId) => _onMovedToCart(
          productId,
          emit,
        ),
        WishlistRemovalUndone() => _onRemovalUndone(emit),
        WishlistCatalogUpdated(:final products) => _onCatalogUpdated(
          products,
          emit,
        ),
        WishlistRepositoriesSwitched(
          :final wishlistRepository,
          :final productRepository,
        ) =>
          _onRepositoriesSwitched(wishlistRepository, productRepository, emit),
      },
      transformer: sequential(),
    );
    _followCatalog();
    add(const WishlistStarted());
  }

  /// Listens to the current product repository's catalog, and stops
  /// listening to the previous one.
  void _followCatalog() {
    unawaited(_catalogSubscription?.cancel());
    _catalogSubscription = _productRepository.productStream.listen(
      (products) => add(WishlistCatalogUpdated(products)),
    );
  }

  Future<void> _onStarted(Emitter<WishlistState> emit) async {
    final result = await _wishlistRepository.loadEntries().run();
    emit(WishlistLoaded(result.getOrElse((_) => const [])));
  }

  Future<void> _onRepositoriesSwitched(
    IWishlistRepository wishlistRepository,
    IProductRepository productRepository,
    Emitter<WishlistState> emit,
  ) async {
    _wishlistRepository = wishlistRepository;
    _productRepository = productRepository;
    _followCatalog();
    // The removed entry belongs to the old Data Source's Wishlist.
    _lastRemoved = null;
    emit(const WishlistLoading());
    await _onStarted(emit);
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
    await _save(current.withEntries(entries), emit);
  }

  Future<void> _onRemoved(String productId, Emitter<WishlistState> emit) async {
    final current = state;
    if (current is! WishlistLoaded) return;
    final removed = current.entries
        .where((entry) => entry.productId == productId)
        .firstOrNull;
    if (removed == null) return;

    final saved = await _save(
      current.withEntries([
        for (final entry in current.entries)
          if (entry.productId != productId) entry,
      ], outcome: RemovedOutcome(removed)),
      emit,
    );
    if (saved) _lastRemoved = removed;
  }

  Future<void> _onMovedToCart(
    String productId,
    Emitter<WishlistState> emit,
  ) async {
    final current = state;
    if (current is! WishlistLoaded || !current.canMoveToCart(productId)) {
      return;
    }
    final moved = current.entries.firstWhere(
      (entry) => entry.productId == productId,
    );
    await _save(
      current.withEntries([
        for (final entry in current.entries)
          if (entry.productId != productId) entry,
      ], outcome: MovedToCartOutcome(moved)),
      emit,
    );
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
    if (!await _save(current.withEntries(entries), emit)) {
      _lastRemoved = removed;
    }
  }

  Future<void> _onCatalogUpdated(
    List<Product> products,
    Emitter<WishlistState> emit,
  ) async {
    final current = state;
    if (current is! WishlistLoaded) return;
    final latest = {for (final product in products) product.id: product};
    final entries = [
      for (final entry in current.entries)
        switch (latest[entry.productId]) {
          final product? => entry.withDetails(product),
          // No Longer Available: keep its last-known details.
          null => entry,
        },
    ];
    final catalogIds = latest.keys.toSet();
    final next = WishlistLoaded(entries, catalogIds: catalogIds);
    if (listEquals(entries, current.entries)) {
      emit(next);
      return;
    }
    if (!await _save(next, emit)) {
      // No Longer Available follows the catalog, not storage, so it still
      // applies; the refreshed details aren't shown as they weren't saved.
      emit(WishlistLoaded(current.entries, catalogIds: catalogIds));
    }
  }

  /// Saves [next]'s entries and, once they are safely stored, emits [next].
  /// If saving fails the Wishlist stays as it was, so the screen never shows
  /// a change that would be lost on restart. Returns whether it was saved.
  Future<bool> _save(WishlistLoaded next, Emitter<WishlistState> emit) async {
    final result = await _wishlistRepository.saveEntries(next.entries).run();
    if (result.isLeft()) return false;
    emit(next);
    return true;
  }

  @override
  Future<void> close() async {
    await _catalogSubscription?.cancel();
    return super.close();
  }
}
