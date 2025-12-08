final Result a = Result.success('Entity created');
final Result b = Result.failure('Entity created');
final Result c = Result.networkFailure('Entity created');

class Result {
  bool success;
  String? message;
  String? error;
  List<dynamic>? data;
  Object? object;

  Result({
    required this.success,
    this.message,
    this.error,
    this.data,
    this.object,
  });

  factory Result.success(
    String? message, {
    List<dynamic>? data,
    Object? object,
  }) {
    return Result(success: true, message: message, data: data, object: object);
  }

  factory Result.failure(String? error, {List<dynamic>? data, Object? object}) =
      FailureResult;

  factory Result.networkFailure(
    String? error, {
    List<dynamic>? data,
    Object? object,
  }) = FailureResult.networt;
}

class FailureResult extends Result {
  FailureResult(String? error, {super.data, super.object})
    : super(success: false, error: error);

  FailureResult.networt(String? error, {super.data, super.object})
    : super(success: false, error: error);
}
