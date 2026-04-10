//
//  AuthManager.swift
//  Space Shooter  Game
//
//  Created by Antigravity on 10/04/26.
//

import Foundation

struct User: Codable {
    let email: String
    let password: String // In a real app, this should be hashed
    var highScore: Int = 0
}

class AuthManager {
    static let shared = AuthManager()
    
    private let usersKey = "stored_users"
    private let loggedInUserKey = "current_user_email"
    private let maxUsers = 3
    
    private init() {}
    
    // MARK: - User Management
    
    func getAllUsers() -> [User] {
        guard let data = UserDefaults.standard.data(forKey: usersKey),
              let users = try? JSONDecoder().decode([User].self, from: data) else {
            return []
        }
        return users
    }
    
    func signUp(email: String, password: String) -> (success: Bool, message: String) {
        var users = getAllUsers()
        
        if users.count >= maxUsers {
            return (false, "Registration limit reached. Only 3 users allowed for this trial.")
        }
        
        if users.contains(where: { $0.email == email }) {
            return (false, "User already exists.")
        }
        
        let newUser = User(email: email, password: password)
        users.append(newUser)
        
        saveUsers(users)
        setCurrentUser(email: email)
        return (true, "Success")
    }
    
    func login(email: String, password: String) -> Bool {
        let users = getAllUsers()
        if let _ = users.first(where: { $0.email == email && $0.password == password }) {
            setCurrentUser(email: email)
            return true
        }
        return false
    }
    
    func logout() {
        UserDefaults.standard.removeObject(forKey: loggedInUserKey)
    }
    
    var isLoggedIn: Bool {
        return UserDefaults.standard.string(forKey: loggedInUserKey) != nil
    }
    
    var currentUser: User? {
        guard let email = UserDefaults.standard.string(forKey: loggedInUserKey) else { return nil }
        return getAllUsers().first(where: { $0.email == email })
    }
    
    func updateHighScore(_ newScore: Int) {
        guard let currentEmail = UserDefaults.standard.string(forKey: loggedInUserKey) else { return }
        var users = getAllUsers()
        
        if let index = users.firstIndex(where: { $0.email == currentEmail }) {
            if newScore > users[index].highScore {
                users[index].highScore = newScore
                saveUsers(users)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func saveUsers(_ users: [User]) {
        if let data = try? JSONEncoder().encode(users) {
            UserDefaults.standard.set(data, forKey: usersKey)
        }
    }
    
    private func setCurrentUser(email: String) {
        UserDefaults.standard.set(email, forKey: loggedInUserKey)
    }
}
