# IncentivlyIOSSDK

A Swift package for iOS revenue sharing that passively monitors StoreKit 2 transactions and reports them to your API. The SDK does not handle purchases or know about products - it only listens for and reports completed transactions.

## Features

- 🛒 StoreKit 2 transaction monitoring
- 🌐 API client for handling network requests
- 📊 Automatic transaction reporting
- 🔧 Easy setup and initialization
- ✅ Comprehensive error handling
- 🎯 Passive monitoring (no product knowledge or purchase handling)
- 📝 Detailed logging for debugging API requests
- 👤 User registration and management
- 💾 Local storage for user identifiers
- 💳 Automatic payment reporting and verification
- 🔄 User identifier updates
- 🚫 Duplicate transaction prevention

## Requirements

- iOS 15.0+ / macOS 12.0+
- Xcode 13.0+
- Swift 5.7+

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "path-to-your-repo", from: "1.0.0")
]
```

Or add it through Xcode:
1. File → Add Package Dependencies
2. Enter the repository URL
3. Select the version range

## Usage

### 1. Initialize the SDK

```swift
import IncentivlyIOSSDK

// Initialize the SDK with optional logging (call this early in your app lifecycle)
IncentivlySDK.initialize(loggingEnabled: true)

// Enable or disable detailed logging for debugging (optional)
IncentivlySDK.shared.setLoggingEnabled(true)
```

**Important**: Call `IncentivlySDK.initialize()` early in your app lifecycle (e.g., in AppDelegate/SceneDelegate) to ensure no transactions are missed. This can be called before user registration to start monitoring transactions immediately.

### 2. User Registration

Register users with your revenue sharing platform. The SDK automatically handles local storage to prevent multiple registrations:

```swift
// Register a user with a developer key
do {
    let response = try await IncentivlySDK.shared.registerUser(
        devKey: "dk_1a2b3c4d5e_f6g7h8i9j0",
        userIdentifier: "user_unique_id_123" // Optional
    )
    
    if response.success {
        print("User registered successfully!")
        print("User ID: \(response.userIdentifier ?? "unknown")")
        print("Influencer ID: \(response.influencerId ?? "unknown")")
        print("Referral ID: \(response.referralId ?? "unknown")")
        print("Message: \(response.message ?? "unknown")")
    }
} catch {
    print("Registration failed: \(error)")
}

// Check if user is already registered
if IncentivlySDK.shared.isUserRegistered() {
    let userID = IncentivlySDK.shared.getUserIdentifier()
    print("User already registered with ID: \(userID ?? "unknown")")
}
```

**Important**: User registration only happens once per device. Subsequent calls will return the stored user identifier without making API requests.

### 3. Update User Identifier

Update the user identifier both on the server and locally:

```swift
// Update user identifier
do {
    let response = try await IncentivlySDK.shared.updateUserIdentifier(
        newUserIdentifier: "updated_user_identifier_12345"
    )
    
    if response.success {
        print("User identifier updated successfully!")
        print("Updated \(response.registrationsUpdated ?? 0) registration(s)")
        print("Updated \(response.paymentsUpdated ?? 0) payment(s)")
        print("Message: \(response.message ?? "unknown")")
    }
} catch {
    print("Failed to update user identifier: \(error)")
}
```

**Note**: Users must be registered before updating their identifier. The SDK will automatically use the current stored user identifier and developer key.

### 4. Automatic Payment Reporting

The SDK automatically monitors for StoreKit transactions and reports them to your API. No additional code needed! When a user makes a purchase, the SDK will:

1. Detect the transaction
2. Verify it with StoreKit
3. Automatically report it to the payment API
4. Handle the response and log the results
5. Prevent duplicate reporting using transaction ID tracking

### 5. Manual Payment Reporting (Optional)

```swift
// If you need to manually report a payment
do {
    let response = try await IncentivlySDK.shared.reportPayment(
        productId: "com.yourapp.product1",
        iosTransactionId: "2000000123456789"
    )
    
    if response.success {
        print("Payment reported successfully with ID: \(response.paymentId ?? "unknown")")
        print("Message: \(response.message ?? "unknown")")
    }
} catch {
    print("Failed to report payment: \(error)")
}
```

**Note**: The SDK automatically prevents duplicate payment reporting using the same transaction ID.

## API Integration

### User Registration Endpoint

The SDK sends POST requests to `https://incentivly.com/api/register-user` with the following JSON structure:

```json
{
  "devKey": "dk_1a2b3c4d5e_f6g7h8i9j0",
  "userIdentifier": "user_unique_id_123"
}
```

Expected response:

```json
{
  "success": true,
  "userIdentifier": "user_generated_or_provided_id",
  "influencerId": "influencer_user_id",
  "referralId": "ref_used_for_registration",
  "message": "User successfully registered to influencer"
}
```

### Update User Identifier Endpoint

The SDK sends POST requests to `https://incentivly.com/api/update-user-identifier` with the following JSON structure:

```json
{
  "currentUserIdentifier": "user_ccecb23e-83e1-4e4b-a8da-6864f1248e59",
  "newUserIdentifier": "updated_user_identifier_12345",
  "devKey": "dk_mdugwwgg_nhkc6lvqwgs"
}
```

Expected response:

```json
{
  "success": true,
  "message": "Successfully updated userIdentifier. Updated 1 registration(s) and 0 payment(s).",
  "registrationsUpdated": 1,
  "paymentsUpdated": 0
}
```

### Payment Reporting Endpoint

The SDK sends POST requests to `https://incentivly.com/api/report-payment` with the following JSON structure:

```json
{
  "userIdentifier": "user_unique_id_123",
  "productId": "com.yourapp.premium_subscription",
  "iosTransactionId": "2000000123456789",
  "devKey": "dk_1a2b3c4d5e_f6g7h8i9j0"
}
```

Expected response:

```json
{
  "success": true,
  "message": "Payment successfully verified and processed",
  "paymentId": "payment_abc123def456"
}
```

## Error Handling

The SDK provides comprehensive error handling for API operations:

### Payment Errors
- `userNotRegistered`: User must be registered before reporting payments
- `devKeyNotFound`: Developer key not found. Please register user first.
- `invalidTransactionId`: Invalid transaction ID provided.
- `transactionAlreadyProcessed`: This transaction has already been processed.

### User Errors
- `userNotRegistered`: User must be registered before updating identifier
- `devKeyNotFound`: Developer key not found. Please register user first.

### API Errors
- `invalidURL`: The configured API URL is invalid
- `invalidResponse`: Received an invalid response from the server
- `serverError(Int)`: Server returned an error status code
- `encodingError`: Failed to encode request data

## Duplicate Prevention

The SDK automatically prevents duplicate transaction reporting by:

- Tracking processed transaction IDs in local storage
- Checking for duplicates before sending to the server
- Implementing a retry mechanism with a maximum of 5 attempts
- Persisting transaction data across app restarts

## Testing

Run the test suite:

```bash
swift test
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.