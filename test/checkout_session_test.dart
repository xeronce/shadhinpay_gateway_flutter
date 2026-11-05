import 'package:flutter_test/flutter_test.dart';
import 'package:shadhinpay_gateway_flutter/shadhinpay_gateway_flutter.dart';

void main() {
  ShadhinPayCheckoutSession session() => ShadhinPayCheckoutSession(
    paymentId: 'PAY_test',
    paymentUrl: 'https://request.shadhinpay.com/payment/PAY_test',
    returnUrl: 'https://merchant.example/pay/return?state=nonce',
  );
  String callback(String status) =>
      'https://merchant.example/pay/return?state=nonce&paymentId=PAY_test&status=$status';

  test('normalizes both backend callback formats', () {
    for (final entry in {
      'success': ShadhinPayCheckoutOutcome.completed,
      'COMPLETED': ShadhinPayCheckoutOutcome.completed,
      'cancel': ShadhinPayCheckoutOutcome.cancelled,
      'CANCELLED': ShadhinPayCheckoutOutcome.cancelled,
      'failed': ShadhinPayCheckoutOutcome.failed,
      'EXPIRED': ShadhinPayCheckoutOutcome.expired,
      'REFUNDED': ShadhinPayCheckoutOutcome.refunded,
      'INITIATED': ShadhinPayCheckoutOutcome.pending,
      'PENDING': ShadhinPayCheckoutOutcome.pending,
      'future_status': ShadhinPayCheckoutOutcome.unknown,
    }.entries) {
      final result = session().parseReturnUrl(callback(entry.key))!;
      expect(result.outcome, entry.value);
      expect(result.paymentId, 'PAY_test');
      expect(result.callbackStatus, entry.key);
    }
  });

  test('requires exact origin and path', () {
    for (final url in [
      'https://merchant.example.evil.test/pay/return',
      'https://evil.test/pay/return',
      'http://merchant.example/pay/return',
      'https://merchant.example:8443/pay/return',
      'https://merchant.example/pay/return/extra',
      'https://user@merchant.example/pay/return',
    ]) {
      expect(session().parseReturnUrl(url), isNull);
    }
  });

  test('rejects wrong ID, missing state, duplicates and fragments', () {
    for (final url in [
      callback(
        'success',
      ).replaceFirst('paymentId=PAY_test', 'paymentId=PAY_other'),
      callback('success').replaceFirst('state=nonce&', ''),
      callback('success').replaceFirst('state=nonce', 'state=wrong'),
      '${callback('success')}&paymentId=PAY_test',
      '${callback('success')}&paymentID=PAY_test',
      '${callback('success')}&status=failed',
      '${callback('success')}#fragment',
      'https://merchant.example/pay/return?state=nonce&status=success',
    ]) {
      expect(() => session().parseReturnUrl(url), throwsFormatException);
    }
  });

  test('accepts legacy paymentID and missing status as unknown', () {
    expect(
      session()
          .parseReturnUrl(
            callback('success').replaceFirst('paymentId=', 'paymentID='),
          )!
          .outcome,
      ShadhinPayCheckoutOutcome.completed,
    );
    expect(
      session()
          .parseReturnUrl(
            'https://merchant.example/pay/return?state=nonce&paymentId=PAY_test',
          )!
          .outcome,
      ShadhinPayCheckoutOutcome.unknown,
    );
  });

  test('rejects unsafe configuration', () {
    for (final url in [
      'http://example.com',
      '/relative',
      'https://user@example.com',
      'https://example.com/#x',
    ]) {
      expect(
        () => ShadhinPayCheckoutSession(
          paymentId: 'PAY_test',
          paymentUrl: url,
          returnUrl: 'https://merchant.example/return',
        ),
        throwsArgumentError,
      );
    }
    expect(
      () => ShadhinPayCheckoutSession(
        paymentId: '',
        paymentUrl: 'https://example.com/pay',
        returnUrl: 'https://merchant.example/return',
      ),
      throwsArgumentError,
    );
    expect(
      () => ShadhinPayCheckoutSession(
        paymentId: 'PAY_test',
        paymentUrl: 'https://example.com/pay',
        returnUrl: 'https://merchant.example/return?status=success',
      ),
      throwsArgumentError,
    );
  });
}
