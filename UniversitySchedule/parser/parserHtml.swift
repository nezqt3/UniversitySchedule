import SwiftSoup
import Foundation

class parserHtml {
    
    func parseHtml(from urlString: String) async throws -> String {
        guard let url = URL(string: urlString) else { return "" }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let htmlString = String(data: data, encoding: .utf8) else {
                    throw ParserError.invalidData
                }
        
        return try parseHTML(htmlString: htmlString)
    }

}
