import Foundation
import StoreKit

/// API client for handling network requests
internal class APIClient {
    
    private let baseURL: String = "https://incentivly.com/api"
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }
    
    /// Register a user with the revenue sharing API
    /// - Parameters:
    ///   - devKey: Developer key for authentication
    ///   - userIdentifier: Optional user identifier
    /// - Returns: User registration response
    func registerUser(devKey: String, userIdentifier: String? = nil) async throws -> UserRegistrationResponse {
        let request = UserRegistrationRequest(devKey: devKey, userIdentifier: userIdentifier)
        return try await sendRequest(endpoint: "/register-user", method: .POST, body: request)
    }
    
    /// Update user identifier
    /// - Parameters:
    ///   - currentUserIdentifier: Current user identifier
    ///   - newUserIdentifier: New user identifier
    ///   - devKey: Developer key for authentication
    /// - Returns: Update user identifier response
    func updateUserIdentifier(currentUserIdentifier: String, newUserIdentifier: String, devKey: String) async throws -> UpdateUserIdentifierResponse {
        let request = UpdateUserIdentifierRequest(currentUserIdentifier: currentUserIdentifier, newUserIdentifier: newUserIdentifier, devKey: devKey)
        return try await sendRequest(endpoint: "/update-user-identifier", method: .POST, body: request)
    }
    
    /// Report a payment to the revenue sharing API
    /// - Parameters:
    ///   - userIdentifier: User identifier for the payment
    ///   - productId: Product identifier
    ///   - iosTransactionId: iOS transaction ID
    ///   - devKey: Developer key for authentication
    /// - Returns: Payment report response
    func reportPayment(userIdentifier: String, productId: String, iosTransactionId: String, devKey: String) async throws -> PaymentReportResponse {
        let request = PaymentReportRequest(userIdentifier: userIdentifier, productId: productId, iosTransactionId: iosTransactionId, devKey: devKey)
        return try await sendRequest(endpoint: "/report-payment", method: .POST, body: request)
    }
    
    /// Send a generic API request
    /// - Parameters:
    ///   - endpoint: API endpoint path
    ///   - method: HTTP method
    ///   - body: Request body (optional)
    private func sendRequest<T: Codable, R: Codable>(
        endpoint: String,
        method: HTTPMethod,
        body: T? = nil
    ) async throws -> R {
        guard let url = URL(string: baseURL + endpoint) else {
            IncentivlyLogger.shared.logError("Invalid URL: \(baseURL + endpoint)")
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        // Log request details
        IncentivlyLogger.shared.logRequest(
            method: method.rawValue,
            url: url.absoluteString,
            headers: request.allHTTPHeaderFields,
            body: request.httpBody
        )
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            IncentivlyLogger.shared.logError("Invalid response type")
            throw APIError.invalidResponse
        }
        
        // Log response details
        IncentivlyLogger.shared.logResponse(
            statusCode: httpResponse.statusCode,
            headers: httpResponse.allHeaderFields as? [String: String],
            body: data
        )
        
        guard 200...299 ~= httpResponse.statusCode else {
            IncentivlyLogger.shared.logError("Server error with status code: \(httpResponse.statusCode)")
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        do {
            let result = try JSONDecoder().decode(R.self, from: data)
            IncentivlyLogger.shared.logSuccess("API request successful")
            return result
        } catch {
            IncentivlyLogger.shared.logError("Failed to decode response", error: error)
            throw APIError.encodingError
        }
    }
    
    /// Send a generic API request without response parsing (for backward compatibility)
    /// - Parameters:
    ///   - endpoint: API endpoint path
    ///   - method: HTTP method
    ///   - body: Request body (optional)
    private func sendRequest<T: Codable>(
        endpoint: String,
        method: HTTPMethod,
        body: T? = nil
    ) async throws {
        guard let url = URL(string: baseURL + endpoint) else {
            IncentivlyLogger.shared.logError("Invalid URL: \(baseURL + endpoint)")
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        // Log request details
        IncentivlyLogger.shared.logRequest(
            method: method.rawValue,
            url: url.absoluteString,
            headers: request.allHTTPHeaderFields,
            body: request.httpBody
        )
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            IncentivlyLogger.shared.logError("Invalid response type")
            throw APIError.invalidResponse
        }
        
        // Log response details
        IncentivlyLogger.shared.logResponse(
            statusCode: httpResponse.statusCode,
            headers: httpResponse.allHeaderFields as? [String: String],
            body: data
        )
        
        guard 200...299 ~= httpResponse.statusCode else {
            IncentivlyLogger.shared.logError("Server error with status code: \(httpResponse.statusCode)")
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        IncentivlyLogger.shared.logSuccess("Transaction reported successfully")
    }
}

// MARK: - Request Models

/// User registration request
public struct UserRegistrationRequest: Codable {
    let devKey: String
    let userIdentifier: String?
}

/// Update user identifier request
public struct UpdateUserIdentifierRequest: Codable {
    let currentUserIdentifier: String
    let newUserIdentifier: String
    let devKey: String
}

/// Payment report request
public struct PaymentReportRequest: Codable {
    let userIdentifier: String
    let productId: String
    let iosTransactionId: String
    let devKey: String
}

// MARK: - Response Models

/// User registration response
public struct UserRegistrationResponse: Codable {
    let success: Bool
    let userIdentifier: String?
    let influencerId: String?
    let referralId: String?
    let message: String?
}

/// Update user identifier response
public struct UpdateUserIdentifierResponse: Codable {
    let success: Bool
    let message: String?
    let registrationsUpdated: Int?
    let paymentsUpdated: Int?
}

/// Payment report response
public struct PaymentReportResponse: Codable {
    let success: Bool
    let message: String?
    let paymentId: String?
}



/// HTTP methods
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

/// API errors
enum APIError: Error {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case encodingError
}

extension APIError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .serverError(let code):
            return "Server error with code: \(code)"
        case .encodingError:
            return "Encoding error"
        }
    }
}
