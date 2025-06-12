import Foundation

struct Post: Codable, Identifiable {
    let id: Int
    var title: String
    var content: String
    let authorId: Int?
    let createdAt: String
    let updatedAt: String
    let answersCount: Int?
    let views: Int?
    let tags: [String]?
    let answers: [Answer]?
}
