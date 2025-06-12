//
//  MainTabView.swift
//  Queryon
//
//  Created by ohyenmin on 5/20/25.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            // ✅ Q&A 탭 (게시글 검색 및 보기)
            QnaView()
                .tabItem {
                    Image(systemName: "doc.text.magnifyingglass")
                    Text("Q&A")
                }

            // ✅ 답변하기 탭 (질문 목록 + 답변 기능)
            AnswerView()
                .tabItem {
                    Image(systemName: "square.and.pencil")
                    Text("게시판")
                }

            // ✅ 내 메뉴 탭 (로그아웃 등)
            MenuView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("내 메뉴")
                }
        }
        .accentColor(Color(hex: "#6C63FF")) // 선택된 탭 색상 (보라색)
    }
}
