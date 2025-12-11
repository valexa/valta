//
//  StringValidationTests.swift
//  valtaTests
//
//  Created by Vlad on 2025-12-08.
//

import Testing
import Foundation
@testable import valta

struct StringValidationTests {

    @Test func testSanitizedForCSV() {
        let input = "Hello, \"World\"!\nNew Line"
        // Expected: Commas, Quotes, Newlines removed. Exclamation mark kept.
        let result = input.sanitizedForCSV

        // Assert broken chars are gone
        #expect(!result.contains(","))
        #expect(!result.contains("\""))
        #expect(!result.contains("\n"))

        // Assert content is kept
        #expect(result.contains("Hello"))
        #expect(result.contains("World"))
        #expect(result.contains("!"))
        #expect(result.contains("New Line"))
    }

    @Test func testSanitizedOnlyAlphanumeric() {
        let input = "User@Name#123"
        let result = input.sanitizedForCSV
        // @ and # should be preserved now
        #expect(result == "User@Name#123")
    }

    @Test func testCommonPunctuation() {
        let input = "Valid: . - _ ? !"
        let result = input.sanitizedForCSV
        #expect(result == "Valid: . - _ ? !")
    }
}
