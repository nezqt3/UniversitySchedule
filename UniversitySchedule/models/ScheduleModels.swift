//
//  ScheduleModels.swift
//  UniversitySchedule
//
//  Created by Верещагин Илья on 11.09.2025.
//

import Foundation
import SwiftUI

// Урок (пара)
struct Lesson: Identifiable, Hashable {
    let id = UUID()
    let start: DateComponents   // часы/минуты
    let end: DateComponents
    let title: String           // предмет
    let kind: LessonKind        // лекция/семинар/лаб
    let location: String        // аудитория/кампус
    let teacher: String?        // опционально

    // удобные строки времени
    var timeRangeString: String {
        "\(start.hhmm)–\(end.hhmm)"
    }
}

enum LessonKind: String, CaseIterable, Codable {
    case lecture = "Лекция"
    case seminar = "Семинар"
    case lab = "Лабораторная"
    case other = "Другое"

    var iconName: String {
        switch self {
        case .lecture: return "book"
        case .seminar: return "person.2"
        case .lab:     return "testtube.2"
        case .other:   return "square.grid.2x2"
        }
    }
}

// Расписание дня
struct DaySchedule {
    let date: Date
    var lessons: [Lesson]
}

// Хранилище (позже сюда приедет парсинг)
final class ScheduleStore: ObservableObject {
    @Published var today: DaySchedule = SampleData.today()

    // На будущее: дернуть парсер/апи и обновить today
    func refresh() {
        today = SampleData.today() // временно подставляем мок
    }
}

// Formatted hh:mm
fileprivate extension DateComponents {
    var hhmm: String {
        let h = String(format: "%02d", hour ?? 0)
        let m = String(format: "%02d", minute ?? 0)
        return "\(h):\(m)"
    }
}
