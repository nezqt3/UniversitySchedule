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
                .frame(width: 340)
                .padding(12)
        }
        .menuBarExtraStyle(.window)

    }
}

