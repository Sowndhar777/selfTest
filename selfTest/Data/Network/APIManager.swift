//
//  APIManager.swift
//  selfTest
//
//  Created by sowndharrajan on 20/09/26.
//

import Foundation

// 1. Unified HTTP Methods Enum Matrix
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

// 2. Custom Error Tracking Flags
enum NetworkError: Error {
    case invalidURL
    case noDataReceived
    case decodingError
    case serverError(String)
}

class APIManager {
    // Thread-safe structural singleton instance
    static let shared = APIManager()
    private init() {}
    
    /// 🚀 THE UNIVERSAL REQUEST ENGINE: One function to rule them all!
    /// Handles GET, POST, PUT, DELETE with optional payloads, custom headers, and dynamic decoding.
    func request<T: Codable>(
        urlString: String,
        method: HTTPMethod = .get,
        bodyPayload: Data? = nil,
        customHeaders: [String: String]? = nil,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        // 1. Validate the absolute target URL string safely
        guard let cleanURL = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") else {
            completion(.failure(.invalidURL))
            return
        }
        
        // 2. Construct the underlying structural URLRequest configuration
        var request = URLRequest(url: cleanURL)
        request.httpMethod = method.rawValue
        request.httpBody = bodyPayload
        
        // 3. Set standard defaults and overlay custom configuration headers matrix
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let headers = customHeaders {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        // 4. Spawn asynchronous data task worker pipeline
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Always move execution tracking safely back onto the main UI thread pool
            DispatchQueue.main.async {
                if let err = error {
                    completion(.failure(.serverError(err.localizedDescription)))
                    return
                }
                
                guard let incomingData = data else {
                    completion(.failure(.noDataReceived))
                    return
                }
                
                // Non-2xx status -> server error message (e.g. "Email already exists")
                if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                    let json = try? JSONSerialization.jsonObject(with: incomingData) as? [String: Any]
                    let serverMessage = (json?["message"] as? String) ?? (json?["error"] as? String)
                    completion(.failure(.serverError(serverMessage ?? "Server error (code \(http.statusCode)). Please try again.")))
                    return
                }
                
                // 5. Decode backend JSON payload straight into target Swift Models
                do {
                    let decodedStructure = try JSONDecoder().decode(T.self, from: incomingData)
                    completion(.success(decodedStructure))
                } catch {
                    completion(.failure(.decodingError))
                }
            }
        }
        task.resume()
    }
}
