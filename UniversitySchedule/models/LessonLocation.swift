import Foundation

struct LessonLocation: Hashable, Identifiable {
    let id = UUID()
    let room: String
    let teacher: String?
}
