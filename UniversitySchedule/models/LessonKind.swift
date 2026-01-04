import Foundation

enum LessonKind: Hashable, Codable {
    case lecture
    case seminar
    case lab
    case custom(String)

    var rawValue: String {
        switch self {
        case .lecture: return "Лекция"
        case .seminar: return "Семинар"
        case .lab: return "Лабораторная"
        case .custom(let name): return name
        }
    }

    func iconName(forTitle title: String) -> String {
        let lowercasedTitle = title.lowercased()
        switch self {
        case .lecture:
            if lowercasedTitle.contains("матем") { return "function" }
            if lowercasedTitle.contains("физика") { return "atom" }
            return "book"
        case .seminar: return "person.2.circle"
        case .lab: return "testtube.2.circle"
        case .custom: return "square.grid.2x2"
        }
    }
}
