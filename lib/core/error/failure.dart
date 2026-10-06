import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

/// A recoverable error returned from the data or domain layer.
///
/// New code returns [EitherResponse] instead of throwing, so callers handle
/// failures explicitly.
sealed class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Reading from or writing to on-device storage failed.
final class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

/// The result of an asynchronous operation that can fail.
typedef EitherResponse<T> = TaskEither<Failure, T>;
