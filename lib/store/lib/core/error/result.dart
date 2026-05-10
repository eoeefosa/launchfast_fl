import 'failures.dart';

class Result<T> {
  final T? _data;
  final Failure? _failure;

  Result._(this._data, this._failure);

  factory Result.success(T data) => Result._(data, null);
  factory Result.failure(Failure failure) => Result._(null, failure);

  bool get isSuccess => _failure == null;
  bool get isFailure => _failure != null;

  T get data => _data!;
  Failure get failure => _failure!;

  void fold(void Function(T data) onSuccess, void Function(Failure failure) onFailure) {
    if (isSuccess) {
      onSuccess(_data as T);
    } else {
      onFailure(_failure!);
    }
  }
}
