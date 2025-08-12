import XCTest
@testable import IncentivlyIOSSDK

@available(iOS 15.0, macOS 12.0, *)
final class IncentivlyIOSSDKTests: XCTestCase {
    
    var sdk: IncentivlySDK!
    
    override func setUpWithError() throws {
        sdk = IncentivlySDK.shared
    }
    
    override func tearDownWithError() throws {
        sdk = nil
    }
    
    func testSDKInitialization() throws {
        // Test SDK initialization
        XCTAssertNotNil(sdk)
    }
    
    func testUserRegistrationRequest() throws {
        let request = UserRegistrationRequest(devKey: "dk_test123", userIdentifier: "user_123")
        
        XCTAssertEqual(request.devKey, "dk_test123")
        XCTAssertEqual(request.userIdentifier, "user_123")
    }
    
    func testUserRegistrationResponse() throws {
        let response = UserRegistrationResponse(
            success: true,
            userIdentifier: "user_456",
            influencerId: "inf_789",
            referralId: "ref_abc",
            message: "User successfully registered"
        )
        
        XCTAssertTrue(response.success)
        XCTAssertEqual(response.userIdentifier, "user_456")
        XCTAssertEqual(response.influencerId, "inf_789")
        XCTAssertEqual(response.referralId, "ref_abc")
        XCTAssertEqual(response.message, "User successfully registered")
    }
    

    
    func testUpdateUserIdentifierRequest() throws {
        let request = UpdateUserIdentifierRequest(
            currentUserIdentifier: "user_ccecb23e-83e1-4e4b-a8da-6864f1248e59",
            newUserIdentifier: "updated_user_identifier_12345",
            devKey: "dk_mdugwwgg_nhkc6lvqwgs"
        )
        
        XCTAssertEqual(request.currentUserIdentifier, "user_ccecb23e-83e1-4e4b-a8da-6864f1248e59")
        XCTAssertEqual(request.newUserIdentifier, "updated_user_identifier_12345")
        XCTAssertEqual(request.devKey, "dk_mdugwwgg_nhkc6lvqwgs")
    }
    
    func testUpdateUserIdentifierResponse() throws {
        let response = UpdateUserIdentifierResponse(
            success: true,
            message: "Successfully updated userIdentifier. Updated 1 registration(s) and 0 payment(s).",
            registrationsUpdated: 1,
            paymentsUpdated: 0
        )
        
        XCTAssertTrue(response.success)
        XCTAssertEqual(response.message, "Successfully updated userIdentifier. Updated 1 registration(s) and 0 payment(s).")
        XCTAssertEqual(response.registrationsUpdated, 1)
        XCTAssertEqual(response.paymentsUpdated, 0)
    }
    
    func testPaymentReportRequest() throws {
        let request = PaymentReportRequest(
            userIdentifier: "user_123",
            productId: "com.example.premium",
            iosTransactionId: "2000000123456789",
            devKey: "dk_test123"
        )
        
        XCTAssertEqual(request.userIdentifier, "user_123")
        XCTAssertEqual(request.productId, "com.example.premium")
        XCTAssertEqual(request.iosTransactionId, "2000000123456789")
        XCTAssertEqual(request.devKey, "dk_test123")
    }
    
    func testPaymentReportResponse() throws {
        let response = PaymentReportResponse(
            success: true,
            message: "Payment successfully verified and processed",
            paymentId: "payment_abc123def456"
        )
        
        XCTAssertTrue(response.success)
        XCTAssertEqual(response.message, "Payment successfully verified and processed")
        XCTAssertEqual(response.paymentId, "payment_abc123def456")
    }
    

    
    func testPaymentError() throws {
        let error = PaymentError.userNotRegistered
        XCTAssertEqual(error.localizedDescription, "User must be registered before reporting payments")
    }
    
    func testUserError() throws {
        let error = UserError.userNotRegistered
        XCTAssertEqual(error.localizedDescription, "User must be registered before updating identifier")
        
        let devKeyError = UserError.devKeyNotFound
        XCTAssertEqual(devKeyError.localizedDescription, "Developer key not found. Please register user first.")
    }
}