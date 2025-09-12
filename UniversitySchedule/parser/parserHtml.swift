import Foundation
import SwiftSoup

enum GrabErr: LocalizedError {
    case badURL
    case emptyBody
    case http(Int)
    case hostNotFound(String)
    case underlying(Error)
    var errorDescription: String? {
        switch self {
        case .badURL: return "⚠️ Кривой URL"
        case .emptyBody: return "⚠️ Пустой ответ"
        case .http(let s): return "⚠️ HTTP \(s)"
        case .hostNotFound(let h): return "⚠️ Хост не найден: \(h)"
        case .underlying(let e): return e.localizedDescription
        }
    }
}

final class HTMLGrabber {

    func fetchText(from urlString: String, select css: String? = nil) async throws -> Int {
        let data = try await fetchData(urlString: urlString, retries: 3)
        if isJSON(data: data) {
            return try await extractString(from: data, key: "discipline") as! Int? ?? 1
//            return jsonToPrettyString(data) ?? String(data: data, encoding: .utf8) ?? ""
        }
        return 1
    }
    
    func extractString(from data: Data, key: String) async throws -> Any? {
        guard let array = try JSONSerialization.jsonObject(with: data) as? [Any] else {
            return ""
        }
        
        var dict = [Lesson]()
        let now = Date()

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: now)

        for element in array {
            guard let item = element as? [String: Any] else { continue }
            guard let date = item["date"] as? String, date == dateString else { continue }
            guard let kindStr = item["kindOfWork"] as? String else { continue }
            let lessonKind: LessonKind = (kindStr == "Лекции") ? .lecture : .seminar

            guard
                let startTimeString = timeStringToDateComponents(item["beginLesson"] as! String),
                let endTimeString   = timeStringToDateComponents(item["endLesson"]   as! String),
                let title           = item["discipline"]  as? String,
                let location        = item["auditorium"]  as? String,
                let teacher         = item["lecturer"]    as? String
            else { continue }
            let lesson = Lesson(
                start: startTimeString,
                end: endTimeString,
                title: title,
                kind: lessonKind,
                location: location,
                teacher: teacher
            )
            
            dict.append(lesson)
        }
        
        
        SampleData.updateSchedule(with: dict)
        print(dict)
        
        return array.count
    }
    
    func timeStringToDateComponents(_ timeString: String) -> DateComponents? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard let date = formatter.date(from: timeString) else {
            return nil
        }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return components
    }

    private func fetchData(urlString: String, retries: Int) async throws -> Data {
        guard let url = URL(string: urlString) else { throw GrabErr.badURL }

        var req = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
        req.httpMethod = "GET"
        req.setValue("Mozilla/5.0 (Mac; Intel Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        req.setValue("*/*", forHTTPHeaderField: "Accept")
        req.setValue("en-US,en;q=0.9,ru;q=0.8", forHTTPHeaderField: "Accept-Language")

        let cfg = URLSessionConfiguration.ephemeral
        cfg.waitsForConnectivity = true
        cfg.allowsConstrainedNetworkAccess = true
        cfg.allowsExpensiveNetworkAccess = true
        let session = URLSession(configuration: cfg)

        
        var lastErr: Error?
        var attempt = 0
        while attempt <= retries {
            do {
                let (data, resp) = try await session.data(for: req)
                if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                    throw GrabErr.http(http.statusCode)
                }
                guard !data.isEmpty else { throw GrabErr.emptyBody }
                return data
            } catch let ns as NSError {
                if ns.domain == NSURLErrorDomain {
                    switch ns.code {
                    case NSURLErrorCannotFindHost: // -1003
                        throw GrabErr.hostNotFound(url.host ?? url.absoluteString)
                    case NSURLErrorTimedOut, NSURLErrorNetworkConnectionLost, NSURLErrorCannotConnectToHost, NSURLErrorDNSLookupFailed:
                        lastErr = ns
                        let delay = UInt64(pow(2.0, Double(attempt))) * 300_000_000
                        try? await Task.sleep(nanoseconds: delay)
                        attempt += 1
                        continue
                    default:
                        throw GrabErr.underlying(ns)
                    }
                } else {
                    throw GrabErr.underlying(ns)
                }
            }
        }
        throw GrabErr.underlying(lastErr ?? GrabErr.emptyBody)
    }

    private func isJSON(data: Data) -> Bool {
        if data.isEmpty { return false }
        let first = data.first!
        return first == UInt8(ascii: "{") || first == UInt8(ascii: "[")
    }
    private func jsonToPrettyString(_ data: Data) -> String? {
        guard let obj = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted]),
              var s = String(data: pretty, encoding: .utf8) else { return nil }
        s = s.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.joined(separator: "\n")
        return s
    }
}
