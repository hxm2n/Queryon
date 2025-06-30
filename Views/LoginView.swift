import SwiftUI

struct LoginView: View {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @AppStorage("token") var token: String = ""
    @Environment(\.dismiss) var dismiss

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isSecure: Bool = true
    @State private var errorMessage: String?
    @State private var receivedToken: String = ""
    @State private var showResendButton = false
    @State private var pendingUserId: Int?

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()

                // 로고 + 서비스 이름
                VStack(spacing: 10) {
                    Image(systemName: "q.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(Color(hex: "#6C63FF"))

                    Text("Queryon")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "#2C2F5B"))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("이메일")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    TextField("example@dsm.hs.kr", text: $email)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("비밀번호")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Group {
                        if isSecure {
                            SecureField("비밀번호 입력", text: $password)
                        } else {
                            TextField("비밀번호 입력", text: $password)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .overlay(
                        HStack {
                            Spacer()
                            Button(action: {
                                isSecure.toggle()
                            }) {
                                Image(systemName: isSecure ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.gray)
                            }
                            .padding(.trailing, 12)
                        }
                    )
                }
                .padding(.horizontal)

                Button(action: login) {
                    Text("로그인")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "#6C63FF"))
                        .cornerRadius(10)
                        .shadow(color: Color(hex: "#6C63FF").opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .padding(.horizontal)

                if showResendButton, let userId = pendingUserId {
                    Button("인증 메일 재전송") {
                        resendVerification(userId: userId)
                    }
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "#6C63FF"))
                }

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }

                HStack {
                    Text("계정이 없으신가요?")
                        .foregroundColor(.gray)
                    NavigationLink("회원가입", destination: SignUpView())
                        .foregroundColor(Color(hex: "#6C63FF"))
                }

                Spacer()
            }
            .padding(.vertical)
            .navigationBarHidden(true)
            .background(Color(hex: "#F5F7FA").ignoresSafeArea())
        }
    }

    func login() {
        let baseURL = "http://192.168.1.20:3000/api"
        guard let url = URL(string: "\(baseURL)/auth/login") else {
            errorMessage = "서버 주소 오류"
            return
        }

        let body = ["email": email, "password": password]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    errorMessage = "네트워크 오류: \(error.localizedDescription)"
                    return
                }

                guard let data = data, let httpRes = response as? HTTPURLResponse else {
                    errorMessage = "응답 오류"
                    return
                }

                if httpRes.statusCode == 200 {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            print("✅ 응답 JSON:", json)

                            guard let tokenValue = json["token"] as? String else {
                                errorMessage = "토큰 파싱 실패"
                                return
                            }

                            let isVerified = json["isEmailVerified"] as? Bool ?? true
                            // 👉 만약 값이 없으면 기본값 true로 간주 (임시 처리)

                            if isVerified {
                                self.token = tokenValue
                                self.isLoggedIn = true

                                // ✅ 추가: 사용자 이름과 이메일 저장
                                if let name = json["name"] as? String {
                                    UserDefaults.standard.set(name, forKey: "userName")
                                }
                                if let email = json["email"] as? String {
                                    UserDefaults.standard.set(email, forKey: "userEmail")
                                }

                                // ✅ BoardAPIService 토큰 연동
                                BoardAPIService.shared.authToken = tokenValue

                                print("✅ 로그인 성공, 토큰 및 사용자 정보 저장 완료")
                            }

 else {
                                errorMessage = "이메일 인증이 필요합니다."
                            }
                        } else {
                            errorMessage = "응답 JSON 파싱 실패"
                        }
                    } catch {
                        errorMessage = "JSON 파싱 실패: \(error.localizedDescription)"
                    }
                }
 else if httpRes.statusCode == 400 {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let message = json["message"] as? String {
                            errorMessage = message
                            if let needs = json["needsVerification"] as? Bool, needs,
                               let uid = json["userId"] as? Int {
                                showResendButton = true
                                pendingUserId = uid
                            }
                        } else {
                            errorMessage = "알 수 없는 오류"
                        }
                    } catch {
                        errorMessage = "오류 응답 처리 실패"
                    }
                } else {
                    errorMessage = "오류 발생 (코드: \(httpRes.statusCode))"
                }
            }
        }.resume()
    }


    func resendVerification(userId: Int) {
        guard let url = URL(string: "http://192.168.1.20:3000/api/auth/resend-verification") else {
            errorMessage = "서버 주소 오류"
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["userId": userId]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    errorMessage = "재전송 실패: \(error.localizedDescription)"
                    return
                }

                guard let data = data else {
                    errorMessage = "재전송 응답 오류"
                    return
                }

                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let msg = json["message"] as? String {
                    errorMessage = msg
                } else {
                    errorMessage = "재전송 실패"
                }
            }
        }.resume()
    }
}
