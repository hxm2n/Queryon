import SwiftUI

struct QnaView: View {
    @State private var searchKeyword = ""
    @State private var posts: [Post] = []

    var filteredPosts: [Post] {
        posts.filter { post in
            searchKeyword.isEmpty || post.title.localizedCaseInsensitiveContains(searchKeyword)
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
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

                    // 검색창
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("궁금한 걸 검색해보세요", text: $searchKeyword)
                            .foregroundColor(.primary)
                    }
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    .padding(.horizontal)

                    // Q&A 섹션
                    VStack(alignment: .leading, spacing: 12) {

                        ForEach(filteredPosts, id: \.id) { post in
                            NavigationLink(destination: PostDetailView(post: post)) {
                                QnaCardView(post: post, onAnswerTap: {
                                    print("답변 버튼 눌림: \(post.id)")
                                })
                            }
                            .buttonStyle(PlainButtonStyle()) // 기본 화살표 제거
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(hex: "#F5F7FA"))
            
        }
        .navigationViewStyle(StackNavigationViewStyle()) // iPad 대응
        .task {
            do {
                posts = try await BoardAPIService.shared.fetchPosts()
            } catch {
                print("❌ 게시글 불러오기 실패:", error.localizedDescription)
            }
        }
    }
}
