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

struct DaySchedule {
    var date: Date
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
        guard !url.isEmpty else { return }
        if isLoading { return }

        isLoading = true
        
        let df = DateFormatter()
        df.dateFormat = "yyyy.MM.dd"
        let dateStr = df.string(from: today.date)
        
        // API RUZ требует параметры start и finish
        let fullURL = "\(url)?start=\(dateStr)&finish=\(dateStr)"
        print(fullURL)
        
        Task {
            defer { isLoading = false }
            do {
                // 1. Загружаем данные
                let data = try await fetchData(urlString: fullURL)
                
                // 2. Парсим и получаем массив [Lesson]
                let fetchedLessons = try await grabber.extractString(from: data, targetDate: today.date)
                
                // 3. ПРЯМОЕ ОБНОВЛЕНИЕ (SwiftUI это увидит)
                self.today.lessons = fetchedLessons
                
                print("Успешно загружено уроков: \(fetchedLessons.count)")
            } catch {
                print("Ошибка обновления: \(error.localizedDescription)")
            }
        }
        }
    
    private func fetchData(urlString: String) async throws -> Data {
            guard let url = URL(string: urlString) else { throw GrabErr.badURL }
            let (data, _) = try await URLSession.shared.data(from: url)
            return data
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
