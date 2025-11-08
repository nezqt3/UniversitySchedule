<h1>Помощник для macOS</h1>

<h2>Структура проекта</h2>
<pre>
UniversitySchedule/
│
├── data/
│   └── SampleData.swift          # Тестовые данные и примеры расписаний
│
├── models/
│   └── ScheduleModels.swift      # Модели: Lesson, DaySchedule и др.
│
├── parser/
│   └── parserHtml.swift          # HTML-парсер расписания с ruz.fa.ru
│
└── views/
    ├── GlassView.swift           # Компонент стеклянного интерфейса (GlassCard)
    ├── ScheduleView.swift        # Основной экран расписания
    └── ScheduleView_Previews.swift # Превью интерфейса в Xcode
</pre>

📄 Лицензия

Проект распространяется под лицензией MIT.
Свободно используйте, модифицируйте и улучшайте!
