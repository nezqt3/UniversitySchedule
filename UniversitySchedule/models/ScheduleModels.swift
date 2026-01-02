// MARK: - Lesson Models

import Foundation
import SwiftUI

struct LessonLocation: Hashable, Identifiable {
    let id = UUID()
    let room: String
    let teacher: String?
}

// Урок (пара)
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

enum LessonKind: String, CaseIterable, Codable {
    case lecture = "Лекция"
    case seminar = "Семинар"
    case lab = "Лабораторная"
    case other = "Другое"

    func iconName(forTitle title: String) -> String {
        let lowercasedTitle = title.lowercased()
        
        switch self {
        case .lecture:
            if lowercasedTitle.contains("матем") {
                return "function"
            } else if lowercasedTitle.contains("физика") {
                return "atom"
            } else if lowercasedTitle.contains("литература") {
                return "text.book.closed"
            } else {
                return "book"
            }
        case .seminar:
            return "person.2.circle"
        case .lab:
            return "testtube.2.circle"
        case .other:
            return "square.grid.2x2"
        }
    }
}

struct DaySchedule {
    let date: Date
    var lessons: [Lesson]
}

// MARK: - Break Info

struct LessonBreakInfo: Identifiable, Hashable {
    let id = UUID()
    let start: DateComponents
    let end: DateComponents

    var minutes: Int {
        let cal = Calendar.current
        let now = Date()
        guard
            let s = cal.date(bySettingHour: start.hour ?? 0, minute: start.minute ?? 0, second: 0, of: now),
            let e = cal.date(bySettingHour: end.hour ?? 0, minute: end.minute ?? 0, second: 0, of: now)
        else { return 0 }
        return max(Int(e.timeIntervalSince(s)/60), 0)
    }

    var timeRangeString: String { "\(start.hhmm)–\(end.hhmm)" }
}

// MARK: - ScheduleItem

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

// MARK: - Schedule Store

@MainActor
final class ScheduleStore: ObservableObject {
    @Published var today: DaySchedule = SampleData.currentSchedule
    @Published var isLoading = false

    private let grabber = HTMLGrabber()
    public var url = ""

    private var lastRefresh: Date?
    private let cooldown: TimeInterval = 3 * 60 * 60
    private var midnightTimer: DispatchSourceTimer?

    init() {
        scheduleMidnightRefresh()
    }

    func refresh(force: Bool = false) {
        let now = Date()
        let isNewDay = lastRefresh.map { !Calendar.current.isDate($0, inSameDayAs: now) } ?? true
        if !force && !isNewDay, let last = lastRefresh, now.timeIntervalSince(last) < cooldown { return }
        guard !isLoading else { return }

        isLoading = true
        Task {
            defer {
                lastRefresh = Date()
                isLoading = false
                scheduleMidnightRefresh()
            }
            do {
                _ = try await grabber.fetchText(from: url)
                today = SampleData.currentSchedule
            } catch {
                print("refresh error:", error)
            }
        }
    }

    private func scheduleMidnightRefresh() {
        midnightTimer?.cancel()
        let cal = Calendar.current
        guard let nextMidnight = cal.nextDate(after: Date(),
                                              matching: DateComponents(hour: 0, minute: 0, second: 0),
                                              matchingPolicy: .nextTime) else { return }
        let interval = nextMidnight.timeIntervalSinceNow
        let t = DispatchSource.makeTimerSource(queue: .main)
        t.schedule(deadline: .now() + interval,
                   repeating: .seconds(24*60*60),
                   leeway: .seconds(60))
        t.setEventHandler { [weak self] in
            self?.refresh(force: true)
        }
        t.resume()
        midnightTimer = t
    }
}

// MARK: - Extensions

extension DateComponents {
    var hhmm: String {
        String(format: "%02d:%02d", hour ?? 0, minute ?? 0)
    }
}
