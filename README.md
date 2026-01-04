<h1>Помощник для macOS</h1>

<h2>Структура проекта</h2>
<pre>
UniversitySchedule/
│
├── data/
│   └── SampleData.swift
│       # Тестовые данные и мок-расписания для превью и отладки
│
├── models/
│   ├── DaySchedule.swift
│   │   # Модель расписания на конкретный день
│   │
│   ├── Lesson.swift
│   │   # Основная модель занятия (пары)
│   │
│   ├── LessonBreakInfo.swift
│   │   # Информация о перерывах между занятиями
│   │
│   ├── LessonKind.swift
│   │   # Enum с типами занятий (лекция, практика, семинар и т.д.)
│   │
│   ├── LessonLocation.swift
│   │   # Аудитория, корпус, онлайн / офлайн
│   │
│   ├── LessonScheduleItem.swift
│   │   # Элемент расписания (урок или перерыв) для отображения в UI
│   │
│   └── ScheduleModels.swift
│       # Общие структуры, typealias'ы и вспомогательные модели
│
├── parser/
│   └── ParserHtml.swift
│       # HTML-парсер расписания с ruz.fa.ru
│
└── views/
    ├── GlassView.swift
    │   # Компонент стеклянного интерфейса (GlassCard)
    │
    ├── ScheduleView.swift
    │   # Основной экран расписания
    │
    └── ScheduleView_Previews.swift
        │
        # SwiftUI превью расписания
</pre>
