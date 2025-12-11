//
//  String+Validation.swift
//  Shared
//
//  Created by valta-bot.
//

import Foundation

extension String {
    /// Returns a sanitized string safe for CSV export.
    /// Removes characters that could break CSV format:
    /// - Commas (field delimiter)
    /// - Quotes (field enclosure)
    /// - Newlines and carriage returns (row delimiter)
    /// - Tabs (alternate delimiter in some systems)
    var sanitizedForCSV: String {
        return self.filter { char in
            let isInvalid = char == "," || char == "\"" || char == "\t" || char.isNewline
            return !isInvalid
        }
    }
}
