//
//  UniversityScheduleApp.swift
//  UniversitySchedule
//
//  Created by Денис Алексеенко on 11.09.2025.
//

import SwiftUI

@main
struct UniversityScheduleApp: App {
    @StateObject private var store = ScheduleStore()

    var body: some Scene {
        // Меню-бар иконка + поповер
        MenuBarExtra("Schedule", systemImage: "calendar") {
            ScheduleView(store: store)
                .frame(width: 340) // компактная ширина поповера
                .padding(12)
        }
        // (опц.) Окно настроек на будущее
        Settings {
            VStack(alignment: .leading, spacing: 12) {
                Text("Settings").font(.title2)
                Text("Здесь потом добавим выбор группы/логин и т.п.")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(width: 420)
        }
    }
}

