import Foundation

class BoardAPIService {
    static let shared = BoardAPIService()
    private let baseURL = "http://192.168.1.41:3000/api"
    private let tokenKey = "auth_token"
    private var _authToken: String?

    var authToken: String? {
        get {
            if let cached = _authToken {
                return cached
            } else {
                let token = UserDefaults.standard.string(forKey: tokenKey)
                _authToken = token
                return token
            }
        }
        set {
            _authToken = newValue
            if let token = newValue {
                UserDefaults.standard.setValue(token, forKey: tokenKey)
            } else {
                UserDefaults.standard.removeObject(forKey: tokenKey)
            }
            UserDefaults.standard.synchronize()
        }
    }

    // MARK: - 인증

    func register(email: String, password: String, name: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/auth/register") else {
            throw URLError(.badURL)
        }

        let body = ["email": email, "password": password, "name": name]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
            throw URLError(.badServerResponse)
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        authToken = tokenResponse.token
        return tokenResponse.token
    }

    func login(email: String, password: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/auth/login") else {
            throw URLError(.badURL)
        }

        let body = ["email": email, "password": password]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        authToken = tokenResponse.token
        return tokenResponse.token
    }

    // MARK: - 공통 인증 요청 생성

    private func authorizedRequest(url: URL, method: String, body: Data? = nil) throws -> URLRequest {
        guard let token = authToken, !token.isEmpty else {
            throw URLError(.userAuthenticationRequired)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = body
        return request
    }

    // MARK: - 게시글

    func fetchPosts(page: Int = 1, limit: Int = 10, sortBy: String = "createdAt", sortOrder: String = "desc") async throws -> [Post] {
        var components = URLComponents(string: "\(baseURL)/posts")
        components?.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "sortBy", value: sortBy),
            URLQueryItem(name: "sortOrder", value: sortOrder)
        ]

        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        let request = try authorizedRequest(url: url, method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode([Post].self, from: data)
    }

    func fetchPost(id: Int) async throws -> Post {
        guard let url = URL(string: "\(baseURL)/posts/\(id)") else {
            throw URLError(.badURL)
        }

        let request = try authorizedRequest(url: url, method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(Post.self, from: data)
    }

    func createPost(title: String, content: String) async throws -> Post {
        guard let url = URL(string: "\(baseURL)/posts") else {
            throw URLError(.badURL)
        }

        let body = try JSONEncoder().encode(["title": title, "content": content])
        let request = try authorizedRequest(url: url, method: "POST", body: body)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(Post.self, from: data)
    }

    func updatePost(id: Int, title: String, content: String) async throws -> Post {
        guard let url = URL(string: "\(baseURL)/posts/\(id)") else {
            throw URLError(.badURL)
        }

        let body = try JSONEncoder().encode(["title": title, "content": content])
        let request = try authorizedRequest(url: url, method: "PUT", body: body)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(Post.self, from: data)
    }

    func deletePost(id: Int) async throws {
        guard let url = URL(string: "\(baseURL)/posts/\(id)") else {
            throw URLError(.badURL)
        }

        let request = try authorizedRequest(url: url, method: "DELETE")
        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        var currentCount = UserDefaults.standard.integer(forKey: "myQuestions")
        if currentCount > 0 {
            currentCount -= 1
            UserDefaults.standard.setValue(currentCount, forKey: "myQuestions")
        }

        print("✅ 글 삭제 성공: 상태 코드 \(httpResponse.statusCode)")
    }

    // MARK: - 답변

    func createAnswer(postId: Int, content: String) async throws -> Answer {
        guard let url = URL(string: "\(baseURL)/posts/\(postId)/answers") else {
            throw URLError(.badURL)
        }

        let body = try JSONEncoder().encode(["content": content])
        let request = try authorizedRequest(url: url, method: "POST", body: body)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(Answer.self, from: data)
    }
}

// MARK: - Token 응답 구조체
struct TokenResponse: Codable {
    let token: String
}

// MARK: - Answer 모델 구조체
struct Answer: Codable, Identifiable {
    let id: Int
    let content: String
    let createdAt: String
    let postId: Int
    let userId: Int
}
