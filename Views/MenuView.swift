import SwiftUI
import PhotosUI

struct MenuView: View {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @AppStorage("token") var token: String = ""
    @AppStorage("userName") var userName: String = ""
    @AppStorage("userEmail") var userEmail: String = ""

    @State private var myQuestions: Int = 0
    @State private var showPointAlert = false
    @State private var showAdoptAlert = false
    @State private var profileImage: UIImage? = nil
    @State private var showImagePicker = false
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var showWithdrawAlert = false

    var school: String = "대덕소프트웨어마이스터고등학교"
    var selectedAnswers: Int = 1
    var point: Int = 0

    var userKey: String { "myQuestions_\(userEmail)" }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 상단 로고
                HStack(alignment: .top) {
                    HStack(spacing: 6) {
                        Image(systemName: "q.circle.fill")
                            .foregroundColor(Color(hex: "#6C63FF"))
                        Text("Queryon")
                            .font(.title2).bold()
                            .foregroundColor(Color(hex: "#2C2F5B"))
                    }
                    Spacer()
                }
                .padding(.horizontal)
                

                // 사용자 프로필 카드
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(userName)
                                .font(.title3).bold()
                            Text(school)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        ZStack(alignment: .bottomTrailing) {
                            Button(action: {
                                showImagePicker = true
                            }) {
                                if let image = profileImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .clipShape(Circle())
                                        .frame(width: 60, height: 60)
                                } else {
                                    Image(systemName: "person.crop.circle")
                                        .resizable()
                                        .frame(width: 60, height: 60)
                                        .foregroundColor(.gray.opacity(0.4))
                                }
                            }

                            Image(systemName: "camera.fill")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                                .offset(x: 4, y: 4)
                        }
                    }
                }
                .padding()
                .background(.white)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
                .padding(.horizontal)

                // 나의 질문 / 채택된 답변
                HStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text("나의 질문")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text("\(myQuestions)")
                            .font(.title2).bold()
                            .foregroundColor(Color(hex: "#6C63FF"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.03), radius: 3, x: 0, y: 1)

                    Button(action: {
                        showAdoptAlert = true
                    }) {
                        VStack(spacing: 4) {
                            Text("채택된 답변")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text("\(selectedAnswers)")
                                .font(.title2).bold()
                                .foregroundColor(Color(hex: "#6C63FF"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.03), radius: 3, x: 0, y: 1)
                    }
                }
                .padding(.horizontal)

                // 포인트
                Button(action: {
                    showPointAlert = true
                }) {
                    HStack {
                        Text("POINT")
                            .font(.subheadline).bold()
                        Spacer()
                        Text("\(point) zp")
                            .font(.title3).bold()
                            .foregroundColor(Color(hex: "#6C63FF"))
                    }
                    .padding()
                    .background(.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.03), radius: 3, x: 0, y: 1)
                }
                .padding(.horizontal)

                // 로그아웃 / 탈퇴
                VStack(spacing: 12) {
                    Button(action: {
                        UserDefaults.standard.removeObject(forKey: "token")
                        UserDefaults.standard.removeObject(forKey: "userEmail")
                        isLoggedIn = false
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "rectangle.portrait.and.arrow.forward")
                            Text("로그아웃")
                        }
                        .foregroundColor(.primary)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.white)
                        .cornerRadius(10)
                    }

                    Button(action: {
                        showWithdrawAlert = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "person.crop.circle.badge.xmark")
                            Text("회원 탈퇴")
                        }
                        .foregroundColor(.red)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.white)
                        .cornerRadius(10)
                    }
                    .alert("잠깐만요!", isPresented: $showWithdrawAlert) {
                        Button("확인", role: .cancel) {}
                    } message: {
                        Text("회원탈퇴하지 마세요... 🥺\n더 나은 서비스를 제공하도록 하겠습니다!")
                    }

                }
                .padding(.horizontal)
            }
            .padding(.bottom, 40)
        }
        .background(Color(hex: "#F5F7FA").ignoresSafeArea())
        .alert("죄송합니다", isPresented: $showPointAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("아직 Point 기능은 개발 중입니다!\n빠른 시일 내에 개발하겠습니다!")
        }
        .alert("죄송합니다", isPresented: $showAdoptAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("아직 채택 기능이 존재하지 않습니다.\n빨리 개발하겠습니다~")
        }
        .photosPicker(isPresented: $showImagePicker, selection: $selectedItem, matching: .images)
        .onChange(of: selectedItem) { newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    profileImage = image
                    UserDefaults.standard.set(data, forKey: "profileImageData_\(userEmail)")
                }
            }
        }
        .onAppear {
            myQuestions = UserDefaults.standard.integer(forKey: userKey)
            if let data = UserDefaults.standard.data(forKey: "profileImageData_\(userEmail)"),
               let image = UIImage(data: data) {
                profileImage = image
            }
        }
    }
}
