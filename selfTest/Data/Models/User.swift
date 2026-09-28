//
//  User.swift
//  selfTest
//
//  Created by sowndharrajan on 20/09/26.
//

import Foundation

// DummyJSON  POST /auth/login  response
struct AuthResponse: Codable {
    let id: Int
    let username: String
    let email: String
    let firstName: String
    let lastName: String
    let accessToken: String
    let refreshToken: String?
}

// DummyJSON  POST /users/add  response (simulated create, not persisted)
struct RegisterResponse: Codable {
    let id: Int?
    let firstName: String?
    let lastName: String?
    let email: String?
}

// DummyJSON  PUT /users/{id}  response (simulated update, not persisted)
struct UserUpdateResponse: Codable {
    let id: Int?
    let firstName: String?
}
