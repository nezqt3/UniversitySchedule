import SwiftSoup
import Foundation

class parserHtml {
    
    func parseHtml(from urlString: String) async throws -> String {
        guard let url = URL(string: urlString) else { return "" }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let htmlString = String(data: data, encoding: .utf8) else {
                    return ""
                }
        
        return try parseHTML(htmlString: htmlString)
    }
    
    func parseHTML(htmlString: String) throws -> String {
        let doc: Document = try SwiftSoup.parse(htmlString)
        let text: String = try doc.text()
        return text
    }
}


