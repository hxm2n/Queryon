import SwiftUI

struct PostDetailView: View {
    let post: Post

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                postHeader
                postContent
                postTags
            }
            .padding()
        }
        .navigationTitle("질문 상세")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var postHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(post.title)
                .font(.title2).bold()

            Text(formatDate(post.createdAt))
                .font(.caption)
                .foregroundColor(.gray)
        }
    }

    private var postContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
            Text(post.content)
                .font(.body)
        }
    }

    private var postTags: some View {
        if let tags = post.tags, !tags.isEmpty {
            return AnyView(
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
            )
        } else {
            return AnyView(EmptyView())
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
