import SwiftUI

struct QnaCardView: View {
    let post: Post
    var onAnswerTap: () -> Void
    
    @State private var showEditView = false
    @State private var showDeleteAlert = false
    @AppStorage("myQuestions") var myQuestions: Int = 0
    
    var body: some View {
        ZStack {
            NavigationLink(destination: PostDetailView(post: post)) {
                EmptyView()
            }
            .opacity(0)
            
            VStack(alignment: .leading, spacing: 10) {
                Text(post.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                if !post.content.isEmpty {
                    Text(post.content)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .truncationMode(.tail)
                }
                
                HStack {
                    Spacer()
                    Text(formatDate(post.createdAt))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                if let tags = post.tags, !tags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption2)
                                .foregroundColor(Color(hex: "#6C63FF"))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(hex: "#ECEBFF"))
                                .cornerRadius(6)
                        }
                    }
                }
                
                HStack {
                    Spacer()
                    
                    Button(action: onAnswerTap) {
                        Text("답변하기")
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(hex: "#6C63FF"))
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button("수정") {
                        showEditView = true
                    }
                    .font(.footnote)
                    .foregroundColor(.blue)
                    .buttonStyle(PlainButtonStyle())
                    .sheet(isPresented: $showEditView) {
                        PostWriteView(editingPost: post)
                    }
                    
                    Button("삭제") {
                        showDeleteAlert = true
                    }
                    .font(.footnote)
                    .foregroundColor(.red)
                    .buttonStyle(PlainButtonStyle())
                    .alert("정말 삭제하시겠습니까?", isPresented: $showDeleteAlert) {
                        Button("삭제", role: .destructive) {
                            Task {
                                do {
                                    try await BoardAPIService.shared.deletePost(id: post.id)
                                    let userEmail = UserDefaults.standard.string(forKey: "userEmail") ?? "unknown"
                                    let key = "myQuestions_\(userEmail)"
                                    let currentCount = UserDefaults.standard.integer(forKey: key)
                                    let newCount = max(currentCount - 1, 0)
                                    UserDefaults.standard.setValue(newCount, forKey: key)
                                } catch {
                                    print("❌ 삭제 실패: \(error)")
                                }
                            }
                        }
                        Button("취소", role: .cancel) {}
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.06), radius: 2, x: 0, y: 1)
            .padding(.vertical, 4)
        }
    }
    
    func formatDate(_ isoString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "yyyy.MM.dd"
        
        if let date = isoFormatter.date(from: isoString) {
            return displayFormatter.string(from: date)
        } else {
            return isoString
        }
    }
}
