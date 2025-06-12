import SwiftUI

struct AnswerWriteView: View {
    let post: Post
    @Environment(\.dismiss) var dismiss
    @State private var answerText = ""
    @State private var showAlert = false

    var body: some View {
        VStack(spacing: 0) {
            // 상단 바
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(Color(hex: "#6C63FF"))
                }

                Spacer()

                Text("답변 작성")
                    .font(.headline)
                    .foregroundColor(Color(hex: "#2C2F5B"))

                Spacer()

                Image(systemName: "q.circle.fill")
                    .foregroundColor(Color(hex: "#6C63FF"))
                    .font(.title3)
            }
            .padding()
            .background(Color.white)
            .overlay(Divider(), alignment: .bottom)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 질문 정보
                    VStack(alignment: .leading, spacing: 6) {
                        Text("질문")
                            .font(.subheadline).bold()
                            .foregroundColor(.gray)

                        Text(post.title)
                            .font(.body)
                            .foregroundColor(.primary)

                        Text(post.content)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)

                    // 답변 에디터
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "#DDDDDD"), lineWidth: 1)
                            .background(Color.white)
                            .frame(minHeight: 200)

                        TextEditor(text: $answerText)
                            .padding(12)
                            .frame(minHeight: 200)
                            .foregroundColor(.primary)

                        if answerText.isEmpty {
                            Text("어떤 답변을 작성하시겠어요?")
                                .foregroundColor(.gray)
                                .padding(18)
                        }
                    }

                    // 제출 버튼
                    Button(action: {
                        if answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            showAlert = true
                        } else {
                            print("✅ 답변 제출됨: \(answerText)")
                            dismiss()
                        }
                    }) {
                        Text("답변 제출")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "#6C63FF"))
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
            .background(Color(hex: "#F5F7FA"))
        }
        .navigationBarHidden(true)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("내용 없음"),
                message: Text("답변을 입력해주세요!"),
                dismissButton: .default(Text("확인"))
            )
        }
    }
}
