import 'package:flutter/material.dart';
import 'package:shadhinpay_gateway_flutter/shadhinpay_gateway_flutter.dart';

void main() => runApp(const MaterialApp(home: CheckoutExample()));

class CheckoutExample extends StatefulWidget {
  const CheckoutExample({super.key});

  @override
  State<CheckoutExample> createState() => _CheckoutExampleState();
}

class _CheckoutExampleState extends State<CheckoutExample> {
  bool _busy = false;
  String _message = 'Create a sandbox payment on your backend first.';

  Future<void> _open() async {
    setState(() => _busy = true);
    try {
      // Demo only: pass details created by your backend through --dart-define.
      // Real apps fetch these through their normal authenticated backend client.
      final session = ShadhinPayCheckoutSession(
        paymentId: const String.fromEnvironment('PAYMENT_ID'),
        paymentUrl: const String.fromEnvironment('PAYMENT_URL'),
        returnUrl: const String.fromEnvironment('RETURN_URL'),
      );
      final result =
          await ShadhinPayCheckout.open(context: context, session: session);
      if (!mounted) return;
      setState(() => _message = 'Checkout signal: ${result.outcome.name}. '
          'Not verified. Ask your backend to verify ${result.paymentId} before fulfillment.');
    } on ArgumentError {
      if (mounted)
        setState(() =>
            _message = 'Provide valid PAYMENT_ID, PAYMENT_URL and RETURN_URL.');
    } on UnsupportedError {
      if (mounted) setState(() => _message = 'Run on Android or iOS.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('ShadhinPay example')),
        body: Center(
            child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
                onPressed: _busy ? null : _open,
                child: const Text('Open checkout')),
          ]),
        )),
      );
}
