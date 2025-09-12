//
//  ScheduleView.swift
//  UniversitySchedule
//
//  Created by Верещагин Илья on 11.09.2025.
//

import SwiftUI

struct ScheduleView: View {
    @ObservedObject var store: ScheduleStore
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            if store.today.lessons.isEmpty {
                emptyState
            } else {
                lessonsList
            }
            footer
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Расписание на сегодня")
                    .font(.headline)
                Text(dateString(store.today.date))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                Task {
                    do {
                        let myres = try await getInformationAboutWeb()
                        print(myres)
                        store.refresh()
                    } catch {
                        print("Ошибка парсинга: \(error)")
                    }
                }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .imageScale(.medium)
                    .help("Обновить")
            }
            .buttonStyle(.borderless)
            .padding(.trailing, 9)

        }
    }

    private var lessonsList: some View {
        let items = buildItems(store.today.lessons)
        return VStack(spacing: 8) {
            ForEach(items) { item in
                switch item {
                case .lesson(let l):
                    LessonRow(lesson: l, isNow: isNow(l))
                case .break(let b):
                    BreakRow(info: b)
                }
            }
        }
    }


    private var emptyState: some View {
        HStack(spacing: 8) {
            Image(systemName: "sun.max")
            Text("Сегодня занятий нет 🎉")
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 24)
    }
    
    private var breakBetweenLessons: some View {
        VStack(spacing: 4) {
            Spacer()
            }
        }
    

    private var footer: some View {
        HStack {
            Text(getGroupInfo())
            Spacer()
            
            Menu {
                Button("Открыть настройки…") {
                    NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
                }
                Divider()
                Button("Выйти", role: .destructive) { NSApp.terminate(nil) }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .symbolRenderingMode(.monochrome)
            }
            .labelStyle(.iconOnly)
            .menuStyle(.borderlessButton)
            .fixedSize()
            .tint(.secondary)
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .padding(.top, 6)
//        .padding(.trailing, 8)
    }

    // MARK: - Helpers
    private func getGroupInfo() -> String {
        let Group = "ТРПО25-2" // В дальнейшем задавать группу через настройки чтобы пользователь мог выбрать
        return Group
    }
    
    private func dateString(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = .init(identifier: "ru_RU")
        df.setLocalizedDateFormatFromTemplate("EEEE, d MMM")
        return df.string(from: date).capitalized
    }


    private func isNow(_ lesson: Lesson) -> Bool {
        let cal = Calendar.current
        let now = Date()
        guard
            let start = cal.date(bySettingHour: lesson.start.hour ?? 0,
                                 minute: lesson.start.minute ?? 0,
                                 second: 0, of: now),
            let end = cal.date(bySettingHour: lesson.end.hour ?? 0,
                               minute: lesson.end.minute ?? 0,
                               second: 0, of: now)
        else { return false }
        return now >= start && now <= end
    }
    
    func getInformationAboutWeb() async throws -> String{
        let parser = parserHtml()
        let url = "https://ruz.fa.ru/ruz/main"
        let result = try await parser.parseHtml(from: url)
        return result
    }
    
    private func buildItems(_ lessons: [Lesson]) -> [ScheduleItem] {
        guard !lessons.isEmpty else { return [] }
        let cal = Calendar.current
        let now = Date()

        func toDate(_ c: DateComponents) -> Date {
            cal.date(bySettingHour: c.hour ?? 0, minute: c.minute ?? 0, second: 0, of: now) ?? now
        }

        let sorted = lessons.sorted { toDate($0.start) < toDate($1.start) }
        var items: [ScheduleItem] = [.lesson(sorted[0])]

        for i in 0..<(sorted.count - 1) {
            let cur = sorted[i]
            let next = sorted[i + 1]
            let curEnd = toDate(cur.end)
            let nextStart = toDate(next.start)
            if nextStart > curEnd {
                // есть окно → вставляем перемену
                let br = BreakInfo(start: cur.end, end: next.start)
                items.append(.break(br))
            }
            items.append(.lesson(next))
        }
        return items
    }

    private func nextLesson() -> Lesson? {
        let cal = Calendar.current
        let now = Date()
        return store.today.lessons.first(where: { l in
            guard let start = cal.date(bySettingHour: l.start.hour ?? 0,
                                       minute: l.start.minute ?? 0,
                                       second: 0, of: now)
            else { return false }
            return start > now
        })
    }
}
struct BreakRow: View {
    let info: BreakInfo

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "cup.and.saucer.fill")
                .frame(width: 22)
                .opacity(0.8)

            HStack(spacing: 6) {
                Text("Перемена")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("•")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(info.minutes) мин")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("•")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(info.timeRangeString)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)

            Spacer()
        }
        // компактнее: меньше паддинги и более светлый фон
        .padding(.vertical, 4)      // ↓ было 8 у LessonRow
        .padding(.horizontal, 8)
        .background(.gray.opacity(0.04), in: .rect(cornerRadius: 10))
    }
}

struct BreakInfo: Identifiable, Hashable {
    let id = UUID()
    let start: DateComponents
    let end: DateComponents

    var minutes: Int {
        let cal = Calendar.current
        let now = Date()
        guard
            let s = cal.date(bySettingHour: start.hour ?? 0, minute: start.minute ?? 0, second: 0, of: now),
            let e = cal.date(bySettingHour: end.hour ?? 0,   minute: end.minute ?? 0,   second: 0, of: now)
        else { return 0 }
        return max(Int(e.timeIntervalSince(s) / 60), 0)
    }

    var timeRangeString: String { "\(start.hhmm)–\(end.hhmm)" }
}

// то, что будем рендерить в списке
enum ScheduleItem: Identifiable, Hashable {
    case lesson(Lesson)
    case `break`(BreakInfo)

    var id: String {
        switch self {
        case .lesson(let l): return "lesson-\(l.id)"
        case .break(let b):  return "break-\(b.id)"
        }
    }
}
// Отдельная “строка пары”
struct LessonRow: View {
    let lesson: Lesson
    let isNow: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: lesson.kind.iconName)
                .frame(width: 22)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(lesson.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    if isNow {
                        Text("сейчас")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.green.opacity(0.18), in: .capsule)
                    }
                }
                Text("\(lesson.timeRangeString) • \(lesson.kind.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                    Text(lesson.location)
                    if let teacher = lesson.teacher {
                        Text("•")
                        Text(teacher)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }
            Spacer()
        }
        .padding(8)
        .background(isNow ? .green.opacity(0.08) : .gray.opacity(0.06), in: .rect(cornerRadius: 10))
    }
}
