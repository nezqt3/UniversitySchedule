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
import SwiftUI

@MainActor
final class ScheduleStore: ObservableObject {
    @Published var today: DaySchedule = SampleData.currentSchedule
    @Published var isLoading = false

    private let grabber = HTMLGrabber()
    private let url = "https://ruz.fa.ru/api/schedule/group/155274"

    private var lastRefresh: Date?
    private let cooldown: TimeInterval = 3 * 60 * 60   // 3 часа
    private var midnightTimer: DispatchSourceTimer?

    init() {
        scheduleMidnightRefresh()
    }

    func refresh(force: Bool = false) {
        let now = Date()
        let isNewDay = lastRefresh.map { !Calendar.current.isDate($0, inSameDayAs: now) } ?? true

        // если не форс и не новый день — уважай кулдаун
        if !force && !isNewDay, let last = lastRefresh, now.timeIntervalSince(last) < cooldown {
            return
        }
        guard !isLoading else { return }

        isLoading = true
        Task {
            defer {
                self.lastRefresh = Date()
                self.isLoading = false
                self.scheduleMidnightRefresh()   // на случай смены суток во время работы
            }
            do {
                _ = try await grabber.fetchText(from: url) // HTMLGrabber кладёт в SampleData
                self.today = SampleData.currentSchedule     // забираем состояние
            } catch {
                print("refresh error:", error)
            }
        }
    }

    // MARK: - Midnight refresh (каждую полночь, игнорируя кулдаун)
    private func scheduleMidnightRefresh() {
        midnightTimer?.cancel()

        let cal = Calendar.current
        let now = Date()
        guard let nextMidnight = cal.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime
        ) else { return }

        let interval = nextMidnight.timeIntervalSince(now)
        let t = DispatchSource.makeTimerSource(queue: .main)
        t.schedule(
            deadline: .now() + interval,
            repeating: .seconds(24*60*60),
            leeway: .seconds(60)
        )
        t.setEventHandler { [weak self] in
            self?.refresh(force: true) // новое расписание на сегодня
        }
        t.resume()
        midnightTimer = t
    }
}



// Formatted hh:mm
extension DateComponents {
    var hhmm: String {
        let h = String(format: "%02d", hour ?? 0)
        let m = String(format: "%02d", minute ?? 0)
        return "\(h):\(m)"
    }
}
