import 'package:dio/dio.dart';

/// Error of a call to the WorkLog or ONE API, built from a ProblemDetails body when there is one.
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.errors = const {},
    this.isNetwork = false,
    this.requiresTwoFactor = false,
  });

  factory ApiException.from(Object error) {
    if (error is ApiException) return error;
    if (error is DioException) return ApiException.fromDio(error);
    return ApiException(
      message: 'Ocurrió un error inesperado. Inténtalo de nuevo.',
      code: error.runtimeType.toString(),
    );
  }

  factory ApiException.fromDio(DioException e) {
    if (e.error is ApiException) return e.error! as ApiException;
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.transformTimeout:
        return const ApiException(
          message: 'Sin conexión con el servidor. Tu trabajo queda guardado en el teléfono.',
          isNetwork: true,
        );
      case DioExceptionType.cancel:
        return const ApiException(message: 'Se canceló la solicitud.', isNetwork: true);
      case DioExceptionType.badCertificate:
        return const ApiException(message: 'El certificado del servidor no es válido.', isNetwork: true);
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        break;
    }

    final response = e.response;
    if (response == null) {
      return const ApiException(message: 'Sin conexión con el servidor.', isNetwork: true);
    }

    final status = response.statusCode;
    final data = response.data;
    if (data is Map) {
      final errors = <String, List<String>>{};
      final rawErrors = data['errors'];
      if (rawErrors is Map) {
        rawErrors.forEach((key, value) {
          if (value is List) errors['$key'] = value.map((v) => '$v').toList();
        });
      }
      final detail = data['detail'] as String? ?? (errors.isNotEmpty ? errors.values.first.first : null);
      return ApiException(
        statusCode: status,
        code: data['code'] as String?,
        message: detail ?? data['title'] as String? ?? _fallback(status),
        errors: errors,
        requiresTwoFactor: data['requiresTwoFactor'] == true,
      );
    }
    return ApiException(statusCode: status, message: _fallback(status));
  }

  final String message;
  final int? statusCode;

  /// Stable code of the ProblemDetails (`workday.too_early`, `activity.photo`…).
  final String? code;
  final Map<String, List<String>> errors;

  /// No answer from the server: the request can be retried later.
  final bool isNetwork;

  /// ONE login of an account with two-step verification.
  final bool requiresTwoFactor;

  bool get isUnauthorized => statusCode == 401;

  /// Worth retrying later (network or server errors), as opposed to a business rejection.
  bool get isTransient =>
      isNetwork || (statusCode != null && (statusCode! >= 500 || statusCode == 408 || statusCode == 429));

  static String _fallback(int? status) => switch (status) {
    401 => 'Tu sesión expiró. Ingresa de nuevo.',
    403 => 'No tienes permiso para esta acción.',
    404 => 'No se encontró el recurso.',
    _ when status != null && status >= 500 => 'El servidor tuvo un problema. Inténtalo más tarde.',
    _ => 'No se pudo completar la solicitud.',
  };

  @override
  String toString() => 'ApiException($statusCode, $code, $message)';
}
