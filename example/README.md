# Checkout example

Create a sandbox payment using your backend first. Never pass API keys through Dart defines.

Generate local platform runners (not included in the package):

```sh
flutter create --platforms=android,ios .
flutter pub get
```

Add Android Internet permission to `android/app/src/main/AndroidManifest.xml` and ensure Android minimum SDK 24 and iOS deployment target 13.0 or the minimum required by the resolved WebView plugin.

```sh
flutter run \
  --dart-define=PAYMENT_ID=PAY_YOUR_PAYMENT \
  --dart-define=PAYMENT_URL=https://request.shadhinpay.com/payment/PAY_YOUR_PAYMENT \
  --dart-define=RETURN_URL=https://merchant.example/payments/return
```

Use the exact return URL sent as `callbackUrl` when creating this payment, including any state query parameter. Quote command-line values containing `&`.

This demo displays checkout signals only. It intentionally does not claim verified payment success or simulate backend verification. Production apps must verify the order with their backend after checkout and on app resume/restart.
