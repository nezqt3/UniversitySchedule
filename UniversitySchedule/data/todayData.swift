//
//  SampleData.swift
//  UniversitySchedule
//
//  Created by Верещагин Илья on 11.09.2025.
//

import Foundation

enum todayData {
    static func today() -> DaySchedule {
        let calendar = Calendar.current
        let today = Date()

        return DaySchedule(
            date: today,
            lessons: [
                
            ]
        )
    }
}
