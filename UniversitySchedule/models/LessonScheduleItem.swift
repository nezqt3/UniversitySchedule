import Foundation

enum LessonScheduleItem: Identifiable, Hashable {
    case lesson(Lesson)
    case `break`(LessonBreakInfo)

    var id: String {
        switch self {
        case .lesson(let l): return "lesson-\(l.id)"
        case .break(let b): return "break-\(b.id)"
        }
    }
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .lesson(let lesson):
            hasher.combine("lesson")
            hasher.combine(lesson.id)
        case .break(let breakInfo):
            hasher.combine("break")
            hasher.combine(breakInfo.id)
        }
    }
    
    static func == (lhs: LessonScheduleItem, rhs: LessonScheduleItem) -> Bool {
        switch (lhs, rhs) {
        case (.lesson(let l1), .lesson(let l2)):
            return l1.id == l2.id
        case (.break(let b1), .break(let b2)):
            return b1.id == b2.id
        default:
            return false
        }
    }
}
