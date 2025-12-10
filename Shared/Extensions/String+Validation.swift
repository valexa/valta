//
//  String+Validation.swift
//  Shared
//
//  Created by valta-bot.
//

import Foundation

extension String {
    /// Returns a sanitized string containing only alphanumeric characters and spaces.
    /// This ensures CSV integrity by removing potential delimiters like commas, quotes, and newlines.
    var sanitizedForCSV: String {
        return self.filter { char in
            let isInvalid = char == "," || char == "\"" || char.isNewline
            return !isInvalid
        }
    }
}
