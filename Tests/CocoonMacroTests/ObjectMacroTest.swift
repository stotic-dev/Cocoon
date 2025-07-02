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
                @ObjectMember @Persisted var hoge: HogeObject?
                
                convenience init(id: String, name: String, age: Int, hoge: HogeObject.HogeObjectEntity) {
                    self.init()
                    self.id = id
                    self.name = name
                    self.age = age
                    self.hoge = hoge.toRealmObject()
                }
            }
            """,
            expandedSource: """
            final public class SampleObject: Object {
                @Persisted var id: String
                @Persisted var name: String
                @Persisted var age: Int
                @ObjectMember @Persisted var hoge: HogeObject?
                
                convenience init(id: String, name: String, age: Int, hoge: HogeObject.HogeObjectEntity) {
                    self.init()
                    self.id = id
                    self.name = name
                    self.age = age
                    self.hoge = hoge.toRealmObject()
                }
            }
            
            public extension SampleObject {
                typealias EntityType = SampleObjectEntity
                @ObjectEntity
                struct SampleObjectEntity: Sendable {
                    public typealias RealmObject = SampleObject
                    public let id: String
                    public let name: String
                    public let age: Int
                        @ObjectMember public let hoge: HogeObject.EntityType?
                }
            }
            """,
            macros: macros
        )
    }
}
