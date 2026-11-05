# ShadhinPay Gateway for Flutter

Backend-independent hosted checkout for Android and iOS. Works with any backend that calls the ShadhinPay REST API: Node.js, Java, Python, PHP, Laravel or others. The Laravel package is optional.

## Security contract

- Never put merchant API keys or webhook secrets in a mobile app.
- Create payments on your authenticated backend. Calculate amounts from your order, not from client input.
- Treat every checkout result, including `completed`, as an **untrusted navigation signal**.
- Verify payment ID, merchant order, amount, currency and status on your backend before fulfilling an order.
- Closing checkout does not cancel a payment. A payment may complete after dismissal or a network error.

## Install

Once published:

```sh
flutter pub add shadhinpay_gateway_flutter
```

Before publication, use a local path dependency:

```yaml
dependencies:
  shadhinpay_gateway_flutter:
    path: ../shadhinpay-gateway-flutter
```

Requirements: Dart 3.12+, Flutter 3.44+, Android API 24+, iOS 13+. Actual minimums may increase with the resolved `webview_flutter` version; commit your app lockfile and check its platform requirements.

Android: add Internet permission to `android/app/src/main/AndroidManifest.xml`, outside `<application>`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

iOS: HTTPS checkout does not require an App Transport Security exception. No deep-link setup is required for the embedded HTTPS return flow.

## Backend integration (any language)

Your app talks to **your backend** using your normal authentication. Your backend calls:

```http
POST https://request.shadhinpay.com/api/v1/payment/create
Client-Id: YOUR_CLIENT_ID
Business-Id: YOUR_BUSINESS_ID
X-Api-Key: YOUR_SERVER_ONLY_API_KEY
X-Idempotency-Key: STABLE_KEY_FOR_THIS_PAYMENT_ATTEMPT
Content-Type: application/json

{
  "amount": 500,
  "currency": "BDT",
  "merchantTxnId": "ORDER-123",
  "callbackUrl": "https://merchant.example/payments/return?state=UNIQUE_NONCE",
  "description": "Order 123"
}
```

Keep the idempotency key stable when retrying the same request. Use exact decimal arithmetic on your server, never floating-point money calculations.

The ShadhinPay response contains `data.paymentId` and `data.paymentUrl`. Return those to your app along with the **same** HTTPS `callbackUrl`, named `returnUrl` in your app's contract. That name and your backend endpoints are your choice; this SDK makes no requests to your backend.

The return endpoint must be distinct from checkout, must not contain a fragment or pre-existing `paymentId`, `paymentID` or `status` query parameter. A per-attempt `state` query parameter is recommended; the SDK preserves and checks configured query values. Provide a harmless fallback page at that URL for returns outside the embedded checkout; do not fulfill orders based on query parameters.

## Flutter integration

```dart
import 'package:shadhinpay_gateway_flutter/shadhinpay_gateway_flutter.dart';

// Values received from your authenticated backend. Do not accept arbitrary
// checkout URLs from an untrusted user or external deep link.
final session = ShadhinPayCheckoutSession(
  paymentId: response.paymentId,
  paymentUrl: response.paymentUrl,
  returnUrl: response.returnUrl,
);

if (!context.mounted) return;
final result = await ShadhinPayCheckout.open(
  context: context,
  session: session,
);

// Always ask your backend to verify, including after dismissal.
// Your backend must authorize this order for the current user.
await yourBackend.verifyOrderPayment(result.paymentId);
```

Handle `ArgumentError` for invalid session configuration and `UnsupportedError` on unsupported platforms. SDK does not create payments, store credentials, retry backend requests, or assume your backend's routes or authentication.

For verification, your backend calls:

```http
GET https://request.shadhinpay.com/api/v1/payment/PAY_ID
Client-Id: YOUR_CLIENT_ID
Business-Id: YOUR_BUSINESS_ID
X-Api-Key: YOUR_SERVER_ONLY_API_KEY
```

Only an authorized server-side result with `data.status == COMPLETED`, matching order, amount and currency, permits fulfillment. Handle webhooks on your backend for payments that finish after the app closes. Verify webhook signatures there.

## Results

| Outcome | Meaning |
| --- | --- |
| `completed` | Return reported `success` or `COMPLETED`; not verified proof |
| `cancelled` | Return reported `cancel` or `CANCELLED` |
| `failed`, `expired`, `refunded` | Return reported corresponding state |
| `pending` | Return reported `INITIATED` or `PENDING` |
| `unknown` | Missing or unrecognized status; verify with backend |
| `dismissed` | User/system closed checkout without a valid return |

`callbackStatus` preserves the returned status. Wrong payment IDs, duplicate status/ID parameters and mismatched configured return query values are rejected. Return origin and path are matched exactly. No JavaScript bridge or merchant credentials are injected.

## Scope and limitations

- Android/iOS embedded HTTPS checkout only. Web and desktop are not supported.
- External wallet app schemes, pop-up checkout windows and browser handoff are not supported in 0.1.0. A blocked external URL displays an error; closing still returns `dismissed`, not payment failure.
- Vendor WebView compatibility, OTP/3DS and payment returns must be tested in sandbox on real Android/iOS devices before production. Package tests do not certify vendor compatibility.
- No public status polling or automatic timeout claiming a failed payment. Verify pending orders on your backend, including after app restart.
- HTTPS only, including sandbox. No cleartext or TLS-error bypass.
- No refund, webhook receiver or merchant API client in the mobile package.

## Development and publishing

```sh
flutter pub get
dart format --output=none --set-exit-if-changed lib test example/lib
flutter analyze
flutter test
flutter pub publish --dry-run
```

See `example/README.md` for the minimal demo. Before publishing, confirm package-name availability, set your actual public repository/issue tracker metadata in `pubspec.yaml`, review license ownership, and complete Android/iOS sandbox tests. Do not publish credentials or local build files.
