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
    
    @State public var groupName: String = ""
    @State private var showingPopover = false
    @State private var results: [HTMLGrabber.ScheduleItemInfo] = []

    // MARK: BODY
    
    var body: some View {
        TahoeGlassCard(cornerRadius: 24, padding: 12) {
            VStack(alignment: .leading, spacing: 12) {
                header
                    .padding(.horizontal, 4)
                
                if store.today.lessons.isEmpty {
                    emptyState
                } else {
                    lessonsList
                }
                
                footer
            }
        }
        .padding(10)
        .frame(width: 320) // Примерная ширина виджета
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
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.1))
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 0) {
                    Text(groupName.isEmpty ? "Группа не выбрана" : groupName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Text("Текущий выбор")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Правая часть: Кнопка вызова меню
            Button {
                showingPopover.toggle()
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.primary.opacity(0.8))
                    .frame(width: 32, height: 32)
                    .background {
                        Circle()
                            .fill(.white.opacity(0.06))
                            .overlay(
                                Circle()
                                    .stroke(.white.opacity(0.1), lineWidth: 0.5)
                            )
                    }
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showingPopover, arrowEdge: .top) {
                popoverContent
            }
        }
        .padding(.leading, 10)
        .padding(.trailing, 8)
        .padding(.vertical, 8)
        .background {
            // Эффект "вложенной" панели в стиле Tahoe
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.black.opacity(0.25)) // Темная подложка
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.08), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                )
        }
        .padding(.top, 4)
    }


    private var popoverContent: some View {
        VStack(spacing: 12) {
            Text("Выбор расписания")
                .font(.system(size: 14, weight: .bold))
                .padding(.top, 12)

            TextField("Введите название группы", text: $scheduleName)
                .textFieldStyle(.plain)
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.1), lineWidth: 0.5))
                .padding(.horizontal)
                .onSubmit {
                    Task {
                        do {
                            let grabber = HTMLGrabber()
                            results = try await grabber.searchGroup(scheduleName)
                        } catch {
                            print("Ошибка: \(error)")
                        }
                    }
                }

            if results.isEmpty {
                Text("Нет результатов")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .frame(height: 100)
            } else {
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(results) { item in
                            Button {
                                showingPopover = false
                                store.url = "https://ruz.fa.ru/api/schedule/group/\(item.id)"
                                groupName = item.label
                                store.refresh(force: true)
                            } label: {
                                HStack {
                                    Text(item.label)
                                        .font(.system(size: 12))
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.system(size: 10))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 200)
            }

            Button("Закрыть") { showingPopover = false }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .padding(.bottom, 12)
        }
        .frame(width: 280)
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

        // Группируем уроки по времени начала
        let groupedDict = Dictionary(grouping: lessons) { $0.start }

        // Сортировка
        let sortedKeys = groupedDict.keys.sorted { lhs, rhs in
            (lhs.hour ?? 0, lhs.minute ?? 0) < (rhs.hour ?? 0, rhs.minute ?? 0)
        }

        var items: [ScheduleItem] = []
        var previousEnd: Date? = nil

        for key in sortedKeys {
            let group = groupedDict[key]!

            // Если есть разрыв — перемена
            if let prevEnd = previousEnd {
                let firstStart = toDate(group.first!.start)
                if firstStart > prevEnd {
                    let br = BreakInfo(
                        start: cal.dateComponents([.hour, .minute], from: prevEnd),
                        end: group.first!.start
                    )
                    items.append(.break(br))
                }
            }

            // Объединяем все locations одного времени в один урок
            let combinedLocations = group.flatMap { $0.locations }

            // Добавляем объединённый урок (id генерируется автоматически)
            let combinedLesson = Lesson(
                start: group.first!.start,
                end: group.map { $0.end }.max(by: { toDate($0) < toDate($1) }) ?? group.first!.end,
                title: group.first!.title,
                kind: group.first!.kind,
                locations: combinedLocations
            )
            items.append(.lesson(combinedLesson))

            // Обновляем previousEnd
            previousEnd = group.map { toDate($0.end) }.max()
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
        HStack(spacing: 8) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 10))
                .foregroundStyle(.orange)

            Text("Перемена • \(info.minutes) мин • \(info.timeRangeString)")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.orange.opacity(0.9))
            
            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background {
            Capsule()
                .fill(Color.orange.opacity(0.1))
                .overlay(Capsule().stroke(Color.orange.opacity(0.2), lineWidth: 0.5))
        }
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
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: lesson.kind.iconName(forTitle: lesson.title))
                    .frame(width: 18)
                    .foregroundStyle(isNow ? .cyan : .secondary)

                Text(lesson.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                Spacer()

                if isNow {
                    Text("сейчас")
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.cyan.opacity(0.8), in: Capsule())
                        .foregroundStyle(.white)
                }
            }

            Text("\(lesson.timeRangeString) • \(lesson.kind.rawValue)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 24)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(lesson.locations, id: \.room) { loc in
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.caption2)
                        Text(loc.room)
                        if let teacher = loc.teacher {
                            Text("•")
                            Text(teacher)
                        }
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.leading, 24)
        }
        .padding(12)
        // Использование тонкого материала для внутренних карточек
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isNow ? Color.cyan.opacity(0.15) : Color.white.opacity(0.05))
                
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isNow ? .cyan.opacity(0.3) : .white.opacity(0.1), lineWidth: 0.5)
            }
        }
    }
}
