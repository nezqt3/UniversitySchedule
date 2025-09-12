#if DEBUG
import SwiftUI

struct ScheduleView_Previews: PreviewProvider {

    static let storeWithLessons: ScheduleStore = {
        let s = ScheduleStore()
        let now = Date()
        let cal = Calendar.current

        func comps(_ d: Date) -> DateComponents {
            DateComponents(hour: cal.component(.hour, from: d),
                           minute: cal.component(.minute, from: d))
        }

        // первая пара идёт сейчас
        let start1 = cal.date(byAdding: .minute, value: -15, to: now)!
        let end1 = cal.date(byAdding: .minute, value: 60, to: now)!

        // вторая пара потом
        let start2 = cal.date(byAdding: .minute, value: 90, to: now)!
        let end2   = cal.date(byAdding: .minute, value: 180, to: now)!

        s.today = DaySchedule(
            date: now,
            lessons: [
                Lesson(start: comps(start1), end: comps(end1),
                       title: "Матан", kind: .lecture, location: "К-406", teacher: "Петров А.А."),
                Lesson(start: comps(start2), end: comps(end2),
                       title: "Линал", kind: .seminar, location: "Б-203", teacher: "Иванова Н.Н.")
            ]
        )
        return s
    }()

    static let storeEmpty: ScheduleStore = {
        let s = ScheduleStore()
        s.today = DaySchedule(date: Date(), lessons: [])
        return s
    }()

    static var previews: some View {
        Group {
            ScheduleView(store: storeWithLessons)
                .frame(width: 340).padding(12)
                .previewDisplayName("Сегодня с парами")

            ScheduleView(store: storeWithLessons)
                .frame(width: 340).padding(12)
                .environment(\.colorScheme, .dark)
                .previewDisplayName("Тёмная тема")

            ScheduleView(store: storeEmpty)
                .frame(width: 340).padding(12)
                .previewDisplayName("Сегодня пусто")
        }
    }
}
#endif
