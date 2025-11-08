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
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var scheduleId: String = ""
    @State private var scheduleName: String = ""
    @State private var showingScheduleEditor = false
    
    @State public var groupName: String = "ДИРПО25-1с"
    @State private var showingPopover = false
    @State private var results: [HTMLGrabber.ScheduleItem] = []

    // MARK: BODY
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 5) {
                header
                Divider()
                if store.today.lessons.isEmpty {
                    emptyState
                } else {
                    lessonsList
                }
                Divider()
                footer
            }
            .task { store.refresh() }
            .padding(8)
        }
        .padding(4)
    }

    
    // MARK: HEADER
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Расписание на сегодня").font(.headline)
                Text(dateString(store.today.date))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                store.refresh(force: true) // ручной форс, кулдаун обходится
            } label: {
                Group {
                    if store.isLoading {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .imageScale(.medium)
                    }
                }
            }
            .buttonStyle(.borderless)
            .padding(.trailing, 9)
            .disabled(store.isLoading)
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
            Text("Сегодня занятий нет")
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 24)
    }
    
    // MARK: FOOTER

    private var footer: some View {
        GlassCard(cornerRadius: 14, padding: 10, shadowRadius: 10) {
            HStack(spacing: 12) {
                // Название текущей группы
                HStack(spacing: 6) {
                    Image(systemName: "person.3.sequence")
                        .foregroundStyle(.secondary)
                    Text(groupName.isEmpty ? "Группа не выбрана" : groupName)
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }

                Spacer()

                // Кнопка меню
                Button {
                    showingPopover.toggle()
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .font(.system(size: 18))
                        .foregroundStyle(.secondary)
                        .padding(6)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .shadow(radius: 2)
                        )
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showingPopover) {
                    VStack(spacing: 12) {
                        Text("Выбор расписания")
                            .font(.headline)
                            .padding(.top, 8)

                        TextField("Введите название группы", text: $scheduleName)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal)
                            .onSubmit {
                                Task {
                                    do {
                                        let grabber = HTMLGrabber()
                                        results = try await grabber.searchGroup(scheduleName)
                                    } catch {
                                        print("Ошибка при поиске группы: \(error)")
                                    }
                                }
                            }

                        Divider().padding(.horizontal)

                        if results.isEmpty {
                            Text("Нет результатов")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 6) {
                                    ForEach(results) { item in
                                        Button {
                                            showingPopover = false
                                            store.url = "https://ruz.fa.ru/api/schedule/group/\(item.id)"
                                            groupName = item.label
                                            Task {
                                                store.refresh(force: true)
                                            }
                                        } label: {
                                            HStack {
                                                Text(item.label)
                                                    .foregroundColor(.primary)
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            .padding(8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(.thinMaterial)
                                                    .opacity(0.6)
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 8)
                            }
                            .frame(height: 220)
                        }

                        Button("Закрыть") {
                            showingPopover = false
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.bottom, 8)
                    }
                    .frame(width: 320)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .shadow(radius: 20)
                    )
                    .padding()
                }
            }
        }
        .padding(.top, 8)
    }


    // MARK: - Getters/Setters
    
    private mutating func setGroupInfo(groupName: String) {
        self.groupName = groupName
    }
    
    private func getGroupInfo() -> String {
        return self.groupName
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
                // есть окно -> вставляем перемену
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
                Text("Перемена • \(info.minutes) мин • \(info.timeRangeString)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
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
