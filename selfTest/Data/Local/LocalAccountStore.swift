
//
//  LocalAccountStore.swift
//  selfTest
//
//  Registered accounts saved on-device (Core Data entity: LocalAccount).
//  Passwords are NEVER stored as plain text: only a salted SHA-256 hash.
//

import Foundation
import CoreData
import CryptoKit

enum LocalAccountError: LocalizedError {
    case alreadyExists
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .alreadyExists: return "An account with this email already exists. Please log in."
        case .saveFailed:    return "Could not save your account. Please try again."
        }
    }
}

final class LocalAccountStore {

    static let shared = LocalAccountStore()
    private init() {}

    /// Marks a session that came from a local (Core Data) account, not the API
    static let localSessionToken = "local-session"

    private var context: NSManagedObjectContext { CoreDataStack.shared.context }

    // MARK: - Register
    @discardableResult
    func register(firstName: String, lastName: String, username: String,
                  email: String, password: String) -> Result<Void, LocalAccountError> {
        let normalizedEmail = email.lowercased()
        let normalizedUsername = username.lowercased()

        guard findAccount(identifier: normalizedEmail) == nil,
              findAccount(identifier: normalizedUsername) == nil else {
            return .failure(.alreadyExists)
        }

        let salt = Self.makeSalt()
        let account = LocalAccount(context: context)
        account.localUserId = Int64.random(in: 100_000...999_999)   // won't clash with DummyJSON ids
        account.firstName = firstName
        account.lastName = lastName
        account.username = normalizedUsername
        account.email = normalizedEmail
        account.passwordSalt = salt
        account.passwordHash = Self.hash(password: password, salt: salt)
        account.createdAt = Date()

        do {
            try context.save()
            return .success(())
        } catch {
            context.rollback()
            return .failure(.saveFailed)
        }
    }

    func accountExists(email: String) -> Bool {
        findAccount(identifier: email.lowercased()) != nil
    }

    // MARK: - Login
    /// identifier = email OR username. Returns a session object if the password matches.
    func authenticate(identifier: String, password: String) -> AuthResponse? {
        guard let account = findAccount(identifier: identifier.lowercased()),
              let salt = account.passwordSalt,
              let storedHash = account.passwordHash,
              Self.hash(password: password, salt: salt) == storedHash else {
            return nil
        }

        return AuthResponse(
            id: Int(account.localUserId),
            username: account.username ?? "",
            email: account.email ?? "",
            firstName: account.firstName ?? "",
            lastName: account.lastName ?? "",
            accessToken: Self.localSessionToken,
            refreshToken: nil
        )
    }

    // MARK: - Private
    private func findAccount(identifier: String) -> LocalAccount? {
        let request: NSFetchRequest<LocalAccount> = LocalAccount.fetchRequest()
        request.predicate = NSPredicate(format: "email == %@ OR username == %@", identifier, identifier)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    private static func makeSalt() -> String {
        let bytes = (0..<16).map { _ in UInt8.random(in: 0...255) }
        return Data(bytes).base64EncodedString()
    }

    private static func hash(password: String, salt: String) -> String {
        let digest = SHA256.hash(data: Data((salt + password).utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
