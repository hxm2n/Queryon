import SwiftUI

struct AnswerView: View {
    @State private var selectedTab = 0
    @State private var showPostWrite = false
    @State private var selectedPost: Post? = nil
    @State private var posts: [Post] = []

    @AppStorage("myQuestions") var myQuestions: Int = 0

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 상단 바
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

                // 탭
                HStack {
                    Button(action: {
                        selectedTab = 0
                    }) {
                        Text("답변하기")
                            .font(.title3).bold()
                            .foregroundColor(selectedTab == 0 ? .black : .gray)
                    }

                    Spacer()

                    Button(action: {
                        selectedTab = 1
                        showPostWrite = true
                    }) {
                        Text("질문하기")
                            .font(.title3).bold()
                            .foregroundColor(selectedTab == 1 ? .black : .gray)
                    }

                    Spacer()

                    Menu {
                        Button("최신순", action: {})
                        Button("인기순", action: {})
                    } label: {
                        HStack(spacing: 2) {
                            Text("최신순")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 12)
                Divider()

                // 게시글 목록
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(posts) { post in
                            QnaCardView(post: post) {
                                selectedPost = post
                            }
                            .padding(.horizontal)
                        }
                        Spacer(minLength: 80)
                    }
                    .padding(.top)
                }
            }
            .sheet(isPresented: $showPostWrite) {
                PostWriteView()
            }
            .sheet(item: $selectedPost) { post in
                AnswerWriteView(post: post)
            }
            .task {
                do {
                    posts = try await BoardAPIService.shared.fetchPosts()
                } catch {
                    print("❌ 게시글 불러오기 실패:", error.localizedDescription)
                }
            }
            .onChange(of: showPostWrite) { isShowing in
                if isShowing == false {
                    Task {
                        do {
                            posts = try await BoardAPIService.shared.fetchPosts()
                            myQuestions += 1
                            print("🟢 나의 질문 수 증가: \(myQuestions)")
                        } catch {
                            print("❌ 게시글 새로고침 실패:", error.localizedDescription)
                        }
                    }
                }
            }
            .background(Color(hex: "#F5F7FA").ignoresSafeArea())
        }
        .navigationViewStyle(StackNavigationViewStyle()) // iPad 호환성
    }
}
