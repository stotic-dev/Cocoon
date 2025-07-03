//
//  ObjectMacroTest.swift
//  Cocoon
//
//  Created by 佐藤汰一 on 2025/06/24.
//

import CocoonMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class ObjectMacroTest: XCTestCase {
    
    private let macros = ["Object": ObjectMacro.self]
    
    func test() throws {
        assertMacroExpansion(
            """
            @Object
            final public class SampleObject: Object {
                @Persisted var id: String
                @Persisted var name: String
                @Persisted var age: Int
                @Persisted var hoge: HogeObject?
            }
            """,
            expandedSource: """
            final public class SampleObject: Object {
                @Persisted var id: String
                @Persisted var name: String
                @Persisted var age: Int
                @Persisted var hoge: HogeObject?
            }
            
            extension SampleObject {
                public convenience init(id: String, name: String, age: Int, hoge: HogeObject?) {
                    self.init()
                    self.id = id
                    self.name = name
                    self.age = age
                    self.hoge = hoge
                }
            }
            """,
            macros: macros
        )
    }
}
