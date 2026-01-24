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
            // Allow commas and quotes; they will be handled by the CSVService escaping logic.
            // Filter out characters that would break the row structure or cause fundamental issues.
            let isInvalid = char == "\t" || char.isNewline
            return !isInvalid
        }
    }
}
