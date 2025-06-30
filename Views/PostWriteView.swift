import SwiftUI
import PhotosUI

struct PostWriteView: View {
    let editingPost: Post?
    @Environment(\.dismiss) var dismiss

    @State private var title: String
    @State private var content: String
    @State private var tagsText: String
    @State private var showAlert = false
    @State private var showSuccessAlert = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var imageDataList: [Data] = []

    @AppStorage("userEmail") var userEmail: String = ""

    init(editingPost: Post? = nil) {
        self.editingPost = editingPost
        _title = State(initialValue: editingPost?.title ?? "")
        _content = State(initialValue: editingPost?.content ?? "")
        _tagsText = State(initialValue: editingPost?.tags?.map { "#\($0)" }.joined(separator: " ") ?? "")
    }

    var tagList: [String] {
        tagsText
            .replacingOccurrences(of: "#", with: "")
            .components(separatedBy: .whitespaces)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(Color(hex: "#6C63FF"))
                }
                Spacer()
                Text("글쓰기")
                    .font(.headline)
                Spacer()
                Spacer().frame(width: 24)
            }
            .padding(.horizontal)
            .padding(.top)

            TextField("제목을 입력하세요", text: $title)
                .padding()
                .background(Color.white)
                .cornerRadius(10)

            TextField("태그를 입력하세요 (스페이스로 구분)", text: $tagsText)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .onChange(of: tagsText) { newValue in
                    guard !newValue.isEmpty else { return }

                    if let lastChar = newValue.last, lastChar == " ", !newValue.hasSuffix(" #") {
                        let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        tagsText = trimmed + " #"
                    }
                }


            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(hex: "#CCCCCC"), lineWidth: 1)
                    .background(Color.white)

                TextEditor(text: $content)
                    .padding(8)
                    .frame(height: 200)

                if content.isEmpty {
                    Text("본문 내용을 입력하세요")
                        .foregroundColor(.gray)
                        .padding(12)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                PhotosPicker(selection: $selectedPhotos, matching: .images) {
                    Label("사진 첨부", systemImage: "photo.on.rectangle")
                        .foregroundColor(Color(hex: "#6C63FF"))
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(imageDataList.enumerated()), id: \ .offset) { index, data in
                            if let uiImage = UIImage(data: data) {
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipped()
                                        .cornerRadius(10)

                                    Button(action: {
                                        imageDataList.remove(at: index)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.white)
                                            .padding(4)
                                            .background(Color.black.opacity(0.6))
                                            .clipShape(Circle())
                                    }
                                    .padding(6)
                                }
                            }
                        }
                    }
                }
            }

            Spacer()

            Button(action: {
                if title.trimmingCharacters(in: .whitespaces).isEmpty || content.trimmingCharacters(in: .whitespaces).isEmpty {
                    showAlert = true
                } else {
                    Task {
                        await uploadPost(title: title, content: content, tags: tagList, images: imageDataList)
                    }
                }
            }) {
                Text("작성 완료")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "#6C63FF"))
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(hex: "#F5F7FA").ignoresSafeArea())
        .navigationBarHidden(true)
        .alert("입력 누락", isPresented: $showAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("제목과 내용을 모두 입력해주세요.")
        }
        .alert("업로드 성공", isPresented: $showSuccessAlert) {
            Button("확인") {
                dismiss()
            }
        }
        .onChange(of: selectedPhotos) { newItems in
            imageDataList = []
            for item in newItems {
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        imageDataList.append(data)
                    }
                }
            }
        }
    }

    func uploadPost(title: String, content: String, tags: [String], images: [Data]) async {
        guard let url = URL(string: "http://192.168.1.20:3000/api/posts") else { return }
        guard let token = BoardAPIService.shared.authToken else {
            print("❌ 토큰 없음")
            return
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token.trimmingCharacters(in: .whitespacesAndNewlines))", forHTTPHeaderField: "Authorization")

        var body = Data()
        let fields = ["title": title, "content": content]

        for (key, value) in fields {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }

        for tag in tags {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"tags\"\r\n\r\n")
            body.append("\(tag)\r\n")
        }

        for (i, imageData) in images.enumerated() {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"images\"; filename=\"image\(i).jpg\"\r\n")
            body.append("Content-Type: image/jpeg\r\n\r\n")
            body.append(imageData)
            body.append("\r\n")
        }

        body.append("--\(boundary)--\r\n")
        request.httpBody = body

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { return }

            if httpResponse.statusCode == 201 {
                showSuccessAlert = true
                let key = "myQuestions_\(userEmail)"
                let current = UserDefaults.standard.integer(forKey: key)
                UserDefaults.standard.set(current + 1, forKey: key)
                print("✅ \(userEmail)의 질문 수 증가: \(current + 1)")
            } else if httpResponse.statusCode == 401 {
                UserDefaults.standard.removeObject(forKey: "token")
                UserDefaults.standard.set(false, forKey: "isLoggedIn")
                print("❌ 인증 실패: 401")
            } else {
                print("🧾 응답 내용: \(String(data: data, encoding: .utf8) ?? "")")
            }
        } catch {
            print("❌ 업로드 에러: \(error.localizedDescription)")
        }
    }
}

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
