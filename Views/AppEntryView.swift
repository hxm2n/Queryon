import SwiftUI

struct AppEntryView: View {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @AppStorage("token") var token: String = "" // ✅ BoardAPIService와 키 통일
    @AppStorage("myQuestions") var myQuestions: Int = 0 // ✅ 글쓰기 수 저장

    var body: some View {
        Group {
            if isLoggedIn && !isTokenExpired(token) {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .onAppear {
            print("✅ 저장된 토큰:", token)  // ✅ 콘솔에서 확인할 부분!
            UserDefaults.standard.setValue(token, forKey: "auth_token")

            if isLoggedIn && isTokenExpired(token) {
                print("❌ 토큰 만료로 로그아웃 처리됨")
                token = ""
                isLoggedIn = false
            }
        }
    }

    func isTokenExpired(_ token: String) -> Bool {
        guard let payload = decodeJWTPart(token, part: 1),
              let exp = payload["exp"] as? TimeInterval else {
            return true
        }

        let expirationDate = Date(timeIntervalSince1970: exp)
        return Date() >= expirationDate
    }

    func decodeJWTPart(_ token: String, part: Int) -> [String: Any]? {
        let segments = token.components(separatedBy: ".")
        guard segments.count > part else { return nil }

        var base64 = segments[part]
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        while base64.count % 4 != 0 {
            base64.append("=")
        }

        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data),
              let payload = json as? [String: Any] else {
            return nil
        }

        return payload
    }
}
