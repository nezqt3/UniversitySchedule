import Foundation

struct Lesson: Identifiable, Hashable {
    let id = UUID()
    let start: DateComponents
    let end: DateComponents
    let title: String
    let kind: LessonKind
    let locations: [LessonLocation]

    var timeRangeString: String {
        "\(start.hhmm)–\(end.hhmm)"
    }
}
