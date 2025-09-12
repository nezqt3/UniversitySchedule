//
//  SampleData.swift
//  UniversitySchedule
//
//  Created by Верещагин Илья on 11.09.2025.
//

import Foundation

struct SampleData {
    
    static var currentSchedule: DaySchedule = today()
    
    static func today(lessons: [Lesson] = []) -> DaySchedule {
        let today = Date()
        
        return DaySchedule(
            date: today,
            lessons: lessons
        )
        
    }
}
