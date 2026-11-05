import 'checkout_result.dart';

/// Immutable checkout details obtained from your authenticated backend.
class ShadhinPayCheckoutSession {
  ShadhinPayCheckoutSession({
    required this.paymentId,
    required String paymentUrl,
    required String returnUrl,
  }) : paymentUrl = _httpsUrl(paymentUrl, 'paymentUrl'),
       returnUrl = _httpsUrl(returnUrl, 'returnUrl') {
    if (paymentId.isEmpty || paymentId.trim() != paymentId) {
      throw ArgumentError.value(
        paymentId,
        'paymentId',
        'Must not be empty or padded',
      );
    }
    if (this.returnUrl.queryParametersAll.keys.any(
      (key) => const {'paymentId', 'paymentID', 'status'}.contains(key),
    )) {
      throw ArgumentError(
        'returnUrl must not contain paymentId, paymentID or status',
      );
    }
    if (isReturnUrl(this.paymentUrl)) {
      throw ArgumentError(
        'paymentUrl and returnUrl must use different endpoints',
      );
    }
  }

  final String paymentId;
  final Uri paymentUrl;
  final Uri returnUrl;

  static Uri _httpsUrl(String value, String name) {
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment) {
      throw ArgumentError.value(
        value,
        name,
        'Must be an absolute HTTPS URL without user info or fragment',
      );
    }
    return uri;
  }

  /// Exact origin and path match; never uses URL string prefixes.
  bool isReturnUrl(Uri url) =>
      url.scheme == returnUrl.scheme &&
      url.host == returnUrl.host &&
      url.port == returnUrl.port &&
      url.path == returnUrl.path &&
      url.userInfo.isEmpty;

  /// Throws [FormatException] for malformed or mismatched callbacks.
  /// Returns null for navigation that is not the configured return endpoint.
  ShadhinPayCheckoutResult? parseReturnUrl(String value) {
    final url = Uri.tryParse(value);
    if (url == null || !isReturnUrl(url)) return null;
    if (url.hasFragment)
      throw const FormatException('Unexpected return fragment');
    final params = url.queryParametersAll;
    for (final entry in returnUrl.queryParametersAll.entries) {
      final actual = params[entry.key];
      if (actual == null ||
          actual.length != entry.value.length ||
          !Iterable<int>.generate(
            actual.length,
          ).every((i) => actual[i] == entry.value[i])) {
        throw const FormatException(
          'Return query does not match checkout session',
        );
      }
    }
    final ids = [...?params['paymentId'], ...?params['paymentID']];
    if (ids.length != 1 || ids.single != paymentId) {
      throw const FormatException(
        'Return payment ID does not match checkout session',
      );
    }
    final statuses = params['status'];
    if (statuses != null && statuses.length != 1) {
      throw const FormatException('Ambiguous return status');
    }
    final status = statuses?.single;
    final outcome = switch (status?.toUpperCase()) {
      'SUCCESS' || 'COMPLETED' => ShadhinPayCheckoutOutcome.completed,
      'CANCEL' || 'CANCELLED' => ShadhinPayCheckoutOutcome.cancelled,
      'FAILED' => ShadhinPayCheckoutOutcome.failed,
      'EXPIRED' => ShadhinPayCheckoutOutcome.expired,
      'REFUNDED' => ShadhinPayCheckoutOutcome.refunded,
      'INITIATED' || 'PENDING' => ShadhinPayCheckoutOutcome.pending,
      _ => ShadhinPayCheckoutOutcome.unknown,
    };
    return ShadhinPayCheckoutResult(
      paymentId: paymentId,
      outcome: outcome,
      callbackStatus: status,
    );
  }
}
