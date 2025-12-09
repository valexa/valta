//
//  StringValidationTests.swift
//  valtaTests
//
//  Created by ANTIGRAVITY on 2025-12-08.
//

import Testing
import Foundation
@testable import valta

struct StringValidationTests {
    
    @Test func testSanitizedForCSV() {
        let input = "Hello, \"World\"!\nNew Line"
        let expected = "Hello World New Line" // Assuming regex keeps alphanum + space
        
        // Let's check the implementation again:
        // char.isLetter || char.isNumber || char.isWhitespace
        // '!' is punctuation, so it should be removed.
        // '"' is punctuation, removed.
        // ',' is punctuation, removed.
        // '\n' is whitespace, kept.
        
        // Wait, isWhitespace includes newlines.
        // "Hello, \"World\"!\nNew Line"
        // H e l l o [space] W o r l d [newline] N e w [space] L i n e
        // Result: "Hello World\nNew Line"
        
        let result = input.sanitizedForCSV
        
        // Assert that comma and quotes are gone
        #expect(!result.contains(","))
        #expect(!result.contains("\""))
        
        // Assert alphanumerics are kept
        #expect(result.contains("Hello"))
        #expect(result.contains("World"))
        
        // Assert basic punctuation removal
        #expect(!result.contains("!"))
    }
    
    @Test func testSanitizedOnlyAlphanumeric() {
        let input = "User@Name#123"
        let result = input.sanitizedForCSV
        // @ and # should be removed
        #expect(result == "UserName123")
    }
}
