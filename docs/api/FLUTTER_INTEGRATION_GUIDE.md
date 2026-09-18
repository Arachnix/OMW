# OMW Mobile Client (Flutter) Integration Guide

This guide provides the complete blueprint for integrating the Flutter mobile app with the **ON MY WAY (OMW)** backend server.

---

## 1. Network Configuration & Base URLs

Depending on the development environment, configure the base API and WebSocket URLs in Flutter:

| Environment | Base REST URL | WebSocket URL |
|---|---|---|
| **Live Render Cloud (Recommended)** | `https://omw-jout.onrender.com/api` | `wss://omw-jout.onrender.com/ws` |
| **Android Emulator (Local)** | `http://10.0.2.2:3033/api` | `ws://10.0.2.2:3033/ws` |
| **iOS Simulator (Local)** | `http://localhost:3033/api` | `ws://localhost:3033/ws` |
| **Physical Phone (Local LAN / Wi-Fi)** | `http://<YOUR_DEV_MACHINE_IP>:3033/api` | `ws://<YOUR_DEV_MACHINE_IP>:3033/ws` |

> Ensure Android's `AndroidManifest.xml` includes `<uses-permission android:name="android.permission.INTERNET" />` and `android:usesCleartextTraffic="true"` (for local HTTP testing).

---

## 2. Core REST API Endpoints

All endpoints return a standardized JSON envelope:
```json
{
  "success": true,
  "message": "Optional human-readable message",
  "data": { ... }
}
```

### A. Authentication & Profiles
- **Mock Student Login:** `POST /api/auth/login`
  ```json
  // Request Body
  {
    "regNumber": "22BCE1142",
    "name": "Rohit Verma",
    "hostelBlock": "Q Block"
  }
  // Response Body
  {
    "success": true,
    "user": { "id": "usr-rohit", "name": "Rohit Verma", "trustScore": 5.0 },
    "token": "omw_jwt_mock_usr-rohit",
    "wallet": { "availableTokens": 85, "escrowLocked": 0, "runnerStaked": 0 }
  }
  ```
- **Current User Profile & Wallet:** `GET /api/users/me?userId=usr-rohit`
- **Student Public Trust Profile:** `GET /api/users/:id`

---

### B. Dynamic Smart Slider & Tasks Lifecycle
- **Calculate Smart Slider Wager:** `POST /api/tasks/calculate-wager`
  ```json
  // Request
  {
    "pickupNodeId": "loc-main-gate",
    "dropNodeId": "loc-q-block",
    "urgency": "NORMAL",
    "packageWeightKg": 1.5,
    "weatherCondition": "CLEAR",
    "timeOfDay": "EVENING"
  }
  // Response
  {
    "success": true,
    "calculation": {
      "baseWager": 20,
      "recommendedWager": 44,
      "minWager": 15,
      "maxWager": 120,
      "estimatedDistanceMeters": 1039,
      "estimatedWalkMinutes": 14
    }
  }
  ```
- **Fetch Marketplace Feed:** `GET /api/tasks?status=OPEN&lat=12.9692&lng=79.1559&heading=45`
  - *Returns tasks dynamically sorted by corridor spatial proximity and runner walking alignment.*
- **Post Micro-Favor Task:** `POST /api/tasks/create`
  ```json
  {
    "requesterId": "usr-rohit",
    "title": "Collect TT Xerox Lab Manual",
    "description": "Urgent, print 12 pages from counter #3",
    "category": "PRINTING",
    "pickupNodeId": "loc-tt-xerox",
    "dropNodeId": "loc-q-block",
    "wager": 25,
    "urgency": "EXPRESS",
    "packageWeightKg": 0.5
  }
  ```
- **Claim Task (Runner):** `POST /api/tasks/:id/claim`
  ```json
  { "runnerId": "usr-rohan" }
  ```
  *(Locks 25% runner commitment deposit into escrow).*
- **Verify Pickup OTP (Source Handshake):** `POST /api/tasks/:id/verify-pickup`
  ```json
  { "pickupOtp": "782194" }
  ```
- **Verify Delivery OTP (Destination Handshake & Instant Payout):** `POST /api/tasks/:id/verify-delivery`
  ```json
  { "deliveryOtp": "391482" }
  ```
  *(Atomically transfers full bounty to runner and unlocks the runner's 25% stake).*
- **Cancel Task (Requester):** `POST /api/tasks/:id/cancel`
  ```json
  { "userId": "usr-rohit" }
  ```
  *(100% escrow refunded instantly).*

---

### C. Razorpay Token Top-Up & Fiat Cashout
This backend connects natively to the official Flutter `razorpay_flutter` plugin.

1. **Create Razorpay Order:** `POST /api/payments/create-order`
   ```json
   // Request
   { "tokenAmount": 50, "userId": "usr-rohit" }
   // Response
   {
     "success": true,
     "order": {
       "id": "order_TdbA4epM5TShBE",
       "amount": 5000,
       "currency": "INR"
     }
   }
   ```
2. **Verify Signature and Credit Tokens:** `POST /api/payments/verify-payment`
   ```json
   {
     "razorpay_order_id": "order_TdbA4epM5TShBE",
     "razorpay_payment_id": "pay_TdbBxYz987654",
     "razorpay_signature": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
     "tokenAmount": 50,
     "userId": "usr-rohit"
   }
   ```
3. **Runner Fiat Cashout (UPI / Bank):** `POST /api/payments/cashout`
   ```json
   {
     "userId": "usr-rohan",
     "tokens": 40,
     "method": "UPI",
     "destination": "rohan@okhdfcbank"
   }
   ```

---

### D. Campus GIS Map & Navigation
- **24 Landmark Nodes:** `GET /api/map/locations`
  - Returns landmark objects with `id`, `name`, `category`, and `coords: [lat, lng]`.
- **72-Point Road Corridor & 6 Cues:** `GET /api/map/corridor`
  - Returns `waypoints: [[lat, lng], ...]` (72 GPS coordinates) and `turnByTurnCues`.
- **Route Detour & Walk Estimate:** `POST /api/map/route-calculate`
  ```json
  {
    "pickupNodeId": "loc-tt-xerox",
    "dropNodeId": "loc-q-block",
    "runnerOriginNodeId": "loc-main-gate"
  }
  ```

---

### E. TrustShield Deterrence Showcase
- **Editorial Deterrence Cases:** `GET /api/trustshield/showcase`
  - Returns `fraudOfDay` and `fraudOfMonth` case dossiers.

---

## 3. Real-Time WebSocket Streaming (`/ws`)

In Flutter, use `web_socket_channel` to stream live GPS location and receive task alerts.

### Outgoing Events (Flutter App -> Server):
- **Send Runner Telemetry (every 3-5 seconds while in-transit):**
  ```json
  {
    "type": "RUNNER_LOCATION_UPDATE",
    "data": {
      "runnerId": "usr-rohan",
      "lat": 12.9701,
      "lng": 79.1582,
      "speedKmh": 4.8,
      "heading": 65.0,
      "activeTaskId": "TSK-101"
    }
  }
  ```

### Incoming Events (Server -> Flutter App):
- **Live Location Broadcast:**
  ```json
  {
    "type": "RUNNER_LOCATION_BROADCAST",
    "data": {
      "runnerId": "usr-rohan",
      "coords": [12.9701, 79.1582],
      "progressPercent": 48,
      "activeCue": { "cueNumber": 3, "action": "TURN_RIGHT", "instruction": "Turn right toward TT entrance" },
      "telemetry": { "distanceCoveredMeters": 510, "caloriesBurned": 20, "stepCount": 558 }
    }
  }
  ```
- **En-Route Order Intersect Opportunity:**
  ```json
  {
    "type": "EN_ROUTE_TASK_INTERSECT",
    "data": {
      "taskId": "TSK-204",
      "title": "Cold Drink from Gazebo",
      "bounty": 25,
      "distanceMeters": 85,
      "message": "En-Route Opportunity: Task 'Cold Drink from Gazebo' intersects your path (85m away)!"
    }
  }
  ```

---

## 4. Flutter Dart Code Examples

### A. Razorpay Integration in Flutter (`razorpay_flutter`)

```dart
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentController {
  late Razorpay _razorpay;
  // Use live Render URL for real devices/production, or 'http://10.0.2.2:3033/api' for local emulator
  final String baseUrl = 'https://omw-jout.onrender.com/api';

  void initRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  Future<void> purchaseTokens(int tokenAmount, String userId) async {
    // 1. Ask OMW server to create Razorpay test order
    final response = await http.post(
      Uri.parse('$baseUrl/payments/create-order'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'tokenAmount': tokenAmount, 'userId': userId}),
    );

    final data = jsonDecode(response.body);
    if (!data['success']) throw Exception(data['error']);

    final order = data['order'];

    // 2. Launch Razorpay Mobile Checkout Sheet
    var options = {
      'key': 'rzp_test_YourKeyIdHere',
      'amount': order['amount'], // in paise (e.g., 5000 for 50 tokens = ₹50)
      'name': 'ON MY WAY (OMW)',
      'description': 'Purchase $tokenAmount Campus Tokens',
      'order_id': order['id'],
      'prefill': {'contact': '9876543210', 'email': 'student@vitstudent.ac.in'},
      'theme': {'color': '#16A34A'}
    };

    _razorpay.open(options);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // 3. Send signature to OMW server for HMAC verification & token credit
    final verifyRes = await http.post(
      Uri.parse('$baseUrl/payments/verify-payment'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'razorpay_order_id': response.orderId,
        'razorpay_payment_id': response.paymentId,
        'razorpay_signature': response.signature,
        'tokenAmount': 50,
        'userId': 'usr-rohit',
      }),
    );

    print('Tokens credited: ${verifyRes.body}');
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print('Payment Failed: ${response.message}');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}

  void dispose() {
    _razorpay.clear();
  }
}
```

---

### B. WebSocket Telemetry Stream in Flutter (`web_socket_channel`)

```dart
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

class OMWTrackingService {
  late WebSocketChannel _channel;
  // Use live Render WSS URL for real devices/production, or 'ws://10.0.2.2:3033/ws' for local emulator
  final String wsUrl = 'wss://omw-jout.onrender.com/ws';

  void connect({
    required Function(Map<String, dynamic>) onLocationReceived,
    required Function(Map<String, dynamic>) onEnRouteAlert,
  }) {
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    _channel.stream.listen((message) {
      final payload = jsonDecode(message);
      final type = payload['type'];
      final data = payload['data'];

      if (type == 'RUNNER_LOCATION_BROADCAST') {
        onLocationReceived(data);
      } else if (type == 'EN_ROUTE_TASK_INTERSECT') {
        onEnRouteAlert(data);
      }
    });
  }

  void sendRunnerPosition({
    required String runnerId,
    required double lat,
    required double lng,
    double speedKmh = 4.5,
    double heading = 0.0,
    String? activeTaskId,
  }) {
    _channel.sink.add(jsonEncode({
      'type': 'RUNNER_LOCATION_UPDATE',
      'data': {
        'runnerId': runnerId,
        'lat': lat,
        'lng': lng,
        'speedKmh': speedKmh,
        'heading': heading,
        'activeTaskId': activeTaskId,
      }
    }));
  }

  void disconnect() {
    _channel.sink.close();
  }
}
```

---

### C. Map Coordinate Conversion for `flutter_map` or `google_maps_flutter`

All location coordinates are standard `[lat, lng]` floating point arrays:
```dart
import 'package:latlong2/latlong.dart'; // or google_maps_flutter LatLng

LatLng parseCoords(List<dynamic> rawCoords) {
  return LatLng(
    (rawCoords[0] as num).toDouble(),
    (rawCoords[1] as num).toDouble(),
  );
}
```
