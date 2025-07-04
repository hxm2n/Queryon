// QnaListView.swift
import SwiftUI
struct QnaListView: View {
    var body: some View {
        Text("Q&A 전체 리스트")
    }
}

// QnaDetailView.swift
struct QnaDetailView: View {
    var body: some View {
        Text("Q&A 상세 페이지")
    }
}

// MyNewsListView.swift
struct MyNewsListView: View {
    let newsItems: [String]
    var body: some View {
        List(newsItems, id: \.self) { item in
            Text(item)
        }
    }
}

asdfasdfa
