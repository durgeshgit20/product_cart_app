import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
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
        WishlistRemovalUndone() => _onRemovalUndone(emit),
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
    // Catalog updates (Price Drop, No Longer Available) arrive with ticket #5.
    _catalogSubscription = _productRepository.productStream.listen((_) {});
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

  @override
  Future<void> close() async {
    await _catalogSubscription?.cancel();
    return super.close();
  }
}
