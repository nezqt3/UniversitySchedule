//
//  SampleData.swift
//  UniversitySchedule
//
//  Created by Верещагин Илья on 11.09.2025.
//

import Foundation

enum SampleData {
    static func today() -> DaySchedule {
        let calendar = Calendar.current
        let today = Date()

        return DaySchedule(
            date: today,
            lessons: [
                Lesson(
                    start: DateComponents(hour: 9,  minute: 0),
                    end:   DateComponents(hour: 10, minute: 30),
                    title: "Математический анализ",
                    kind: .lecture,
                    location: "К-406",
                    teacher: "Петров А.А."
                ),
                Lesson(
                    start: DateComponents(hour: 10, minute: 40),
                    end:   DateComponents(hour: 12, minute: 10),
                    title: "Линейная алгебра",
                    kind: .seminar,
                    location: "Б-203",
                    teacher: "Иванова Н.Н."
                ),
                Lesson(
                    start: DateComponents(hour: 13, minute: 0),
                    end:   DateComponents(hour: 14, minute: 30),
                    title: "Программирование",
                    kind: .lab,
                    location: "Лаб-12",
                    teacher: "Сергеев Д.В."
                )
            ]
        )
    }
}
