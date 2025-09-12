//
//  SampleData.swift
//  UniversitySchedule
//
//  Created by Верещагин Илья on 11.09.2025.
//

import Foundation

enum SampleData {
    
    static var currentSchedule: DaySchedule = today()
    
    static func today(lessons: [Lesson] = []) -> DaySchedule {
        let today = Date()

        return DaySchedule(date: today, lessons: lessons)
    }
    
    static func updateSchedule(with lessons: [Lesson]) {
            currentSchedule = DaySchedule(date: Date(), lessons: lessons)
        }
}
