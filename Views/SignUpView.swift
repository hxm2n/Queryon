import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @AppStorage("token") var token: String = ""

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isSecure: Bool = true
    @State private var isLoading: Bool = false

    var isFormValid: Bool {
        !name.isEmpty && !email.isEmpty && password.count >= 6
    }

    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: 30) {
                        Spacer().frame(height: 20)

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

                        VStack(spacing: 20) {
                            InputField(title: "이름", placeholder: "이름 입력", text: $name)
                            InputField(title: "이메일", placeholder: "example@dsm.hs.kr", text: $email, keyboardType: .emailAddress, autocapitalization: .never)
                            PasswordField(title: "비밀번호", placeholder: "비밀번호 입력 (6자 이상)", password: $password, isSecure: $isSecure)
                        }
                        .padding(.horizontal)

                        Button(action: signUp) {
                            ZStack {
                                Text("회원가입")
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(isFormValid ? Color(hex: "#6C63FF") : Color.gray)
                                    .cornerRadius(10)
                                    .shadow(color: Color(hex: "#6C63FF").opacity(0.3), radius: 4, x: 0, y: 2)

                                if isLoading {
                                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                                }
                            }
                        }
                        .disabled(!isFormValid || isLoading)
                        .padding(.horizontal)

                        if let error = errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.horizontal)
                                .transition(.opacity)
                        }

                        Button("로그인 화면으로 돌아가기") {
                            dismiss()
                        }
                        .foregroundColor(.gray)
                        .font(.footnote)
                        .disabled(isLoading)

                        Spacer()
                    }
                    .padding(.vertical)
                }
                .navigationBarHidden(true)
                .background(Color(hex: "#F5F7FA").ignoresSafeArea())
            }
        }
    }

    func signUp() {
        guard !isLoading else { return }
        guard isFormValid else {
            errorMessage = "모든 필드를 올바른것으로 입력해주세요."
            return
        }

        isLoading = true
        errorMessage = nil

        let baseURL = "http://192.168.1.41:3000/api"
        guard let url = URL(string: "\(baseURL)/auth/register") else {
            errorMessage = "서버 주소 오류"
            isLoading = false
            return
        }

        let body: [String: String] = [
            "name": name,
            "email": email,
            "password": password
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false

                if let error = error {
                    errorMessage = "네트워크 오류: \(error.localizedDescription)"
                    return
                }

                guard let httpRes = response as? HTTPURLResponse, let data = data else {
                    errorMessage = "서버 응답 오류"
                    return
                }

                switch httpRes.statusCode {
                case 201:
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let tokenValue = json["token"] as? String {
                            token = tokenValue
                            isLoggedIn = true
                            UserDefaults.standard.setValue(name, forKey: "userName") // 이름 저장
                            UserDefaults.standard.setValue(email, forKey: "userEmail") // 이메일 저장
                            print("✅ 토큰 저장 완료: \(tokenValue)")
                            dismiss()
                        } else {
                            errorMessage = "응답에서 토큰을 찾을 수 없습니다."
                        }
                    } catch {
                        errorMessage = "응답 처리 중 오류 발생"
                    }
                case 409:
                    errorMessage = "이미 가입된 이메일입니다."
                case 400:
                    errorMessage = "입력값을 다시 확인해주세요."
                default:
                    let message = String(data: data, encoding: .utf8) ?? "알 수 없는 오류"
                    errorMessage = "오류 발생 (\(httpRes.statusCode)): \(message)"
                }
            }
        }.resume()
    }
}

struct InputField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            TextField(placeholder, text: $text)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(autocapitalization)
                .disableAutocorrection(true)
        }
    }
}

struct PasswordField: View {
    let title: String
    let placeholder: String
    @Binding var password: String
    @Binding var isSecure: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            ZStack(alignment: .trailing) {
                Group {
                    if isSecure {
                        SecureField(placeholder, text: $password)
                    } else {
                        TextField(placeholder, text: $password)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)

                Button(action: { isSecure.toggle() }) {
                    Image(systemName: isSecure ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.gray)
                }
                .padding(.trailing, 12)
            }
        }
    }
}
