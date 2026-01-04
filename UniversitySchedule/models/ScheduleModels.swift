import Foundation
import SwiftUI


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
