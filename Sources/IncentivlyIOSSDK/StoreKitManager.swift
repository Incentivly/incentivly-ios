import Foundation
import StoreKit

/// Manager class for handling StoreKit 2 operations
@available(iOS 15.0, macOS 12.0, *)
internal class StoreKitManager {
    weak var sdk: IncentivlySDK?
    
    private var transactionListener: Task<Void, Error>?
    private var transactionChecker: Task<Void, Error>?
    private var isMonitoringStarted = false
    private let reportLock = NSLock()
    
    /// Start transaction monitoring (called after SDK initialization)
    func startMonitoring() {
        Task {
            await startTransactionMonitoring()
        }
    }
    
    /// Start monitoring for StoreKit transactions
    private func startTransactionMonitoring() async {
        IncentivlyLogger.shared.logInfo("🔄 Starting transaction monitoring...")
        // Prevent multiple listeners from being started
        guard !isMonitoringStarted else {
            IncentivlyLogger.shared.logInfo("⚠️ Transaction monitoring already started, skipping")
            return
        }
        
        // Cancel any existing listener to avoid duplicates
        transactionListener?.cancel()
        
        // Start listening for transactions
        transactionListener = listenForTransactions()
        isMonitoringStarted = true
        
        // Also check for recent transactions in current entitlements
        await checkCurrentEntitlements()
        
        // Start periodic checks for missed transactions
        startPeriodicChecks()
        
        IncentivlyLogger.shared.logInfo("✅ Transaction monitoring started")
    }
    
    deinit {
        IncentivlyLogger.shared.logInfo("StoreKitManager deinit - cancelling transaction listener")
        transactionListener?.cancel()
        transactionChecker?.cancel()
        isMonitoringStarted = false
    }
    
    /// Check current entitlements for recent transactions (catches in-app purchases)
    private func checkCurrentEntitlements() async {
        for await result in Transaction.currentEntitlements {
            guard sdk?.isUserRegistered() ?? false else { return }
            do {
                let transaction = try checkVerified(result)
                await processTransaction(transaction)
            } catch {
                IncentivlyLogger.shared.logError("Failed to verify current entitlement", error: error)
            }
        }
    }
    
    /// Start periodic checks for missed transactions (every 30 seconds)
    private func startPeriodicChecks() {
       transactionChecker = Task.detached { [weak self] in
            while let self = self {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                
                guard isMonitoringStarted else { break }
            
                await checkCurrentEntitlements()
            }
        }
    }
    
    /// Listen for transactions (captures external purchases and renewals)
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached { [weak self] in
            do {
                for await result in Transaction.updates {
                    guard self?.sdk?.isUserRegistered() ?? false else { continue }
                    
                    guard let self = self else {
                        IncentivlyLogger.shared.logError("StoreKitManager deallocated during transaction processing")
                        return
                    }
                    
                    do {
                        let transaction = try checkVerified(result)
                        await processTransaction(transaction)
                    } catch {
                        IncentivlyLogger.shared.logError("Transaction verification failed", error: error)
                    }
                }
            } catch {
                IncentivlyLogger.shared.logError("Transaction monitoring failed with error", error: error)
            }
            
            IncentivlyLogger.shared.logInfo("⚠️ Transaction monitoring stopped")
        }
    }
    
    /// Process a verified transaction (used by both currentEntitlements and updates)
    private func processTransaction(_ transaction: Transaction) async {
        reportLock.lock()
        
        guard Transactions.shouldProcessTransaction(with: transaction.originalID) else {
            reportLock.unlock()
            return
        }

        IncentivlyLogger.shared.logInfo("💳 Processing transaction: \(transaction.productID) (Original ID: \(transaction.originalID), date: \(transaction.purchaseDate))")
//        Report payment to IncentivlySDK
        do {
            try await IncentivlySDK.shared.reportPayment(
                productId: transaction.productID,
                iosTransactionId: String(transaction.originalID)
            )
            Transactions.saveProcessedTransaction(id: transaction.originalID)
            IncentivlyLogger.shared.logInfo("✅ Transaction reported successfully: \(transaction.productID)")
        } catch {
            Transactions.addTransactionReportAttempt(for: transaction.originalID)
            IncentivlyLogger.shared.logError("Failed to report payment to IncentivlySDK", error: error)
        }
        
        // Finish the transaction
        await transaction.finish()
        
        IncentivlyLogger.shared.logInfo("✅ Transaction finished: \(transaction.productID)")
        reportLock.unlock()
    }
    
    /// Verify the transaction using StoreKit's built-in verification
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

/// Custom StoreKit errors
enum StoreKitError: Error {
    case failedVerification
}

extension StoreKitError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Transaction verification failed"
        }
    }
}

internal struct Transactions {
    private static let userDefaults = UserDefaults.standard
    
    private static let processedTransactionsKey = "Incentivly_ProcessedTransactions"
    private static let processedTransactionsLock = NSLock()
    private static var processedTransactionIds: Set<UInt64>?
    
    private static let transactionReportAttemptsKey = "Incentivly_TransactionReportAttempts"
    private static let transactionReportAttemptsLock = NSLock()
    private static let maxTransactionReportAttempts: Int = 5
    private static var transactionReportAttempts: Dictionary<UInt64,Int>?
    
    static func shouldProcessTransaction(with id: UInt64) -> Bool {
        return !getProcessedTransactionIds().contains(id) && getTransactionReportAttempts(for: id) < maxTransactionReportAttempts
    }
    
    static private func getProcessedTransactionIds() -> Set<UInt64> {
        return processedTransactionsLock.withLock {
            if let transactionIds = processedTransactionIds {
                return transactionIds
            } else if let data = userDefaults.data(forKey: processedTransactionsKey),
                      let transactionIds = try? JSONDecoder().decode([UInt64].self, from: data) {
                IncentivlyLogger.shared.logInfo("📂 Loaded \(transactionIds.count) processed transaction IDs from storage")
                processedTransactionIds = Set(transactionIds)
                return processedTransactionIds!
            } else {
                IncentivlyLogger.shared.logInfo("📂 No previously processed transactions found")
                processedTransactionIds = .init()
                return processedTransactionIds!
            }
        }
    }
    
    static func saveProcessedTransaction(id: UInt64) {
        var transactionIds = getProcessedTransactionIds()
        
        processedTransactionsLock.withLock {
            transactionIds.insert(id)
            processedTransactionIds = transactionIds
            
            if let data = try? JSONEncoder().encode(transactionIds) {
                userDefaults.set(data, forKey: processedTransactionsKey)
                IncentivlyLogger.shared.logInfo("💾 Processed transaction (ID: \(id)) saved to storage")
            } else {
                IncentivlyLogger.shared.logError("Failed to encode processed transaction (ID: \(id)) for storage")
            }
        }
    }
    
    private static func getTransactionReportAttemts() -> Dictionary<UInt64,Int> {
        return transactionReportAttemptsLock.withLock {
            if let transactionAttempts = transactionReportAttempts {
                return transactionAttempts
            } else if let data = userDefaults.data(forKey: transactionReportAttemptsKey),
                      let transactionAttempts = try? JSONDecoder().decode(Dictionary<UInt64,Int>.self, from: data) {
                IncentivlyLogger.shared.logInfo("📂 Loaded transaction report attempts with \(transactionAttempts.count) IDs from storage")
                transactionReportAttempts = transactionAttempts
                return transactionReportAttempts!
            } else {
                IncentivlyLogger.shared.logInfo("📂 No previously processed transactions found")
                transactionReportAttempts = .init()
                return transactionReportAttempts!
            }
        }
    }
    
    static private func getTransactionReportAttempts(for id: UInt64) -> Int {
        getTransactionReportAttemts()[id] ?? 0
    }
    
    static func addTransactionReportAttempt(for id: UInt64) {
        var transactionAttempts = getTransactionReportAttemts()
        
        transactionReportAttemptsLock.withLock {
            if transactionAttempts[id] == nil {
                transactionAttempts[id] = 1
            } else {
                transactionAttempts[id]! = transactionAttempts[id]! + 1
            }
            
            transactionReportAttempts = transactionAttempts
            
            if let data = try? JSONEncoder().encode(transactionAttempts) {
                userDefaults.set(data, forKey: transactionReportAttemptsKey)
                IncentivlyLogger.shared.logInfo("💾 Increased transaction report attempts count to \(transactionAttempts[id]!) for transaction (ID: \(id)) and saved to storage")
            } else {
                IncentivlyLogger.shared.logError("Failed to increase transaction report attempts count for transaction (ID: \(id)) and save to storage")
            }
        }
    }
}
