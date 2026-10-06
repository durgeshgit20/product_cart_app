import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/wishlist_entry.dart';
import '../../domain/repositories/i_wishlist_repository.dart';
import '../models/wishlist_entry_dto.dart';

/// Keeps the Wishlist on the device as a JSON list under one
/// `shared_preferences` key.
@LazySingleton(as: IWishlistRepository)
class SharedPreferencesWishlistRepository implements IWishlistRepository {
  static const String storageKey = 'wishlist_entries';

  @override
  EitherResponse<List<WishlistEntry>> loadEntries() => TaskEither.tryCatch(
    () async {
      final prefs = await SharedPreferences.getInstance();
      return _decode(prefs.get(storageKey));
    },
    (error, _) => StorageFailure('Could not load the Wishlist: $error'),
  );

  @override
  EitherResponse<Unit> saveEntries(List<WishlistEntry> entries) =>
      TaskEither.tryCatch(
        () async {
          final prefs = await SharedPreferences.getInstance();
          final json = jsonEncode([
            for (final entry in entries) WishlistEntryDto(entry).toJson(),
          ]);
          final saved = await prefs.setString(storageKey, json);
          if (!saved) throw StateError('storage rejected the write');
          return unit;
        },
        (error, _) => StorageFailure('Could not save the Wishlist: $error'),
      );

  /// Corrupt or unreadable data loads as an empty Wishlist.
  List<WishlistEntry> _decode(Object? raw) {
    if (raw is! String) return const [];
    try {
      return [
        for (final item in jsonDecode(raw) as List<dynamic>)
          WishlistEntryDto.fromJson(item as Map<String, dynamic>).entry,
      ];
    } on FormatException {
      return const [];
    } on TypeError {
      return const [];
    }
  }
}
