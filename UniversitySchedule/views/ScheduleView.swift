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
        .accessibilityElement(children: .contain)
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
                store.refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .imageScale(.medium)
                    .help("Обновить")
            }
            .buttonStyle(.borderless)
        }
    }

    private var lessonsList: some View {
        VStack(spacing: 8) {
            ForEach(store.today.lessons) { lesson in
                LessonRow(lesson: lesson, isNow: isNow(lesson))
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

    private var footer: some View {
        HStack {
            Menu {
                Button("Открыть настройки…") {
                    NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
                }
                Divider()
                Button("Выйти", role: .destructive) { NSApp.terminate(nil) }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.borderlessButton)
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .padding(.top, 6)
    }

    // MARK: - Helpers

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
