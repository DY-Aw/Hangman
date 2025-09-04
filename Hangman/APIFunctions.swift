//
//  APIFunctions.swift
//  Hangman
//
//  Created by Ling on 8/28/25.
//

import Foundation
import Alamofire

struct userIDResponse: Decodable {
    let userID: Int
}

struct WordStats: Identifiable, Codable {
    let id = UUID()
    let word: String
    let played: Int
    let won: Int
    let lost: Int
    
    enum CodingKeys: String, CodingKey {
        case word
        case played
        case won
        case lost
    }
}

class APIFunctions {
    static let functions = APIFunctions()
    private let baseURL = "http://localhost:3000"
    func ping() {
        AF.request("\(baseURL)/ping").response { response in
            print(response.data)
        }
    }
    func update(word: String, win: Int) {
        let parameters: [String: Any] = [
            "word": word,
            "win": win
        ]
        AF.request("\(baseURL)/update", method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
        }
    }
    func updateStats(id: Int, word: String, win: Int) {
        let parameters: [String: Any] = [
            "id": id,
            "word": word,
            "win": win
        ]
        AF.request("\(baseURL)/updateStats", method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
        }
    }
    func login(username: String) {
        let parameters: [String: Any] = [
            "username": username
        ]
        AF.request("\(baseURL)/login", method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
        }
    }
    func returnUserID(username: String) async throws -> Int {
        let parameters: [String: Any] = [
            "username": username
        ]
        return try await withCheckedThrowingContinuation { continuation in
            AF.request("\(baseURL)/returnUserID", parameters: parameters).validate().responseDecodable(of: Int.self) { response in
                    switch response.result {
                    case .success(let userID):
                        continuation.resume(returning: userID)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
        }
    }
    func fetchStats(userid: Int) async throws -> [WordStats] {
        let parameters: [String: Any] = [
            "userid": userid
        ]
        return try await withCheckedThrowingContinuation { continuation in
            AF.request("\(baseURL)/fetchStats", parameters: parameters)
                .validate()
                .responseDecodable(of: [WordStats].self) { (response: AFDataResponse<[WordStats]>) in
                    switch response.result {
                    case .success(let stats):
                        continuation.resume(returning: stats)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
        }
    }
}
