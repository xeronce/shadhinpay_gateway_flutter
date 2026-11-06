import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'checkout_result.dart';
import 'checkout_session.dart';

/// Opens hosted checkout without handling merchant credentials or order creation.
class ShadhinPayCheckout {
  ShadhinPayCheckout._();

  static Future<ShadhinPayCheckoutResult> open({
    required BuildContext context,
    required ShadhinPayCheckoutSession session,
  }) async {
    if (kIsWeb ||
        !(defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      throw UnsupportedError(
        'ShadhinPay checkout supports Android and iOS only',
      );
    }
    final result = await Navigator.of(context).push<ShadhinPayCheckoutResult>(
      MaterialPageRoute(builder: (_) => _CheckoutPage(session: session)),
    );
    return result ??
        ShadhinPayCheckoutResult(
          paymentId: session.paymentId,
          outcome: ShadhinPayCheckoutOutcome.dismissed,
        );
  }
}

class _CheckoutPage extends StatefulWidget {
  const _CheckoutPage({required this.session});
  final ShadhinPayCheckoutSession session;

  @override
  State<_CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<_CheckoutPage> {
  late final WebViewController _controller;
  int _progress = 0;
  String? _error;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (value) {
            if (mounted) setState(() => _progress = value);
          },
          onNavigationRequest: _navigate,
          onWebResourceError: (error) {
            if (mounted && error.isForMainFrame == true) {
              setState(
                () =>
                    _error = 'Checkout could not load. Check your connection.',
              );
            }
          },
        ),
      )
      ..loadRequest(widget.session.paymentUrl);
  }

  NavigationDecision _navigate(NavigationRequest request) {
    if (_finished || !mounted) return NavigationDecision.prevent;
    final uri = Uri.tryParse(request.url);
    // Never let a subframe complete checkout.
    if (uri != null && widget.session.isReturnUrl(uri)) {
      if (!request.isMainFrame) return NavigationDecision.prevent;
      try {
        final result = widget.session.parseReturnUrl(request.url);
        if (result != null) {
          _finished = true;
          Navigator.of(context).pop(result);
        }
      } on FormatException {
        setState(
          () => _error =
              'Checkout return did not match this payment. Close and verify with your merchant.',
        );
      }
      return NavigationDecision.prevent;
    }
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      if (request.isMainFrame) {
        setState(
          () => _error =
              'This payment requires an unsupported external app or URL. Close and verify with your merchant.',
        );
      }
      return NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }

  void _retry() {
    setState(() {
      _error = null;
      _progress = 0;
    });
    // Return to hosted checkout; never resubmit a vendor callback POST.
    _controller.loadRequest(widget.session.paymentUrl);
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF00704A),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1A1A1A),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
    ),
    child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('ShadhinPay'),
        leading: IconButton(
          tooltip: 'Close checkout',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE0E0E0)),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_progress < 100 && _error == null)
              LinearProgressIndicator(
                value: _progress / 100,
                semanticsLabel: 'Loading checkout',
                color: const Color(0xFF00704A),
                backgroundColor: const Color(0xFFE0F2EC),
              ),
            Expanded(
              child: _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _retry,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : WebViewWidget(controller: _controller),
            ),
          ],
        ),
      ),
    ),
  );
}
