import Foundation

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
