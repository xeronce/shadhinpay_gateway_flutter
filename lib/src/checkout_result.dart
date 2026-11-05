/// Checkout signals, not verified payment states.
enum ShadhinPayCheckoutOutcome {
  completed,
  cancelled,
  failed,
  expired,
  refunded,
  pending,
  unknown,
  dismissed,
}

/// Always verify payment, amount, currency and order on your backend.
/// Even [ShadhinPayCheckoutOutcome.completed] is only an untrusted return signal.
class ShadhinPayCheckoutResult {
  const ShadhinPayCheckoutResult({
    required this.paymentId,
    required this.outcome,
    this.callbackStatus,
  });

  final String paymentId;
  final ShadhinPayCheckoutOutcome outcome;
  final String? callbackStatus;
}
