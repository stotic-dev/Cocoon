//
//  ObjectEntityMacroTest.swift
//  Cocoon
//
//  Created by 佐藤汰一 on 2025/06/28.
//

import CocoonMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class ObjectEntityMacroTest: XCTestCase {
    
    private let macros = ["ObjectEntity": ObjectEntityMacro.self]
    
    func test_Entity単体にマクロ付与() throws {
        assertMacroExpansion(
            """
            @ObjectEntity(SampleObject.self)
            public struct SampleObjectEntity: Sendable {
                let id: String
                let name: String
                let age: Int
            }
            """,
            expandedSource: """
            public struct SampleObjectEntity: Sendable {
                let id: String
                let name: String
                let age: Int
            }
            
            extension SampleObjectEntity: BaseRealmEntity {
                public typealias RealmObject = SampleObject
                public init(realmObject: SampleObject) {
                    self.id = realmObject.id
                    self.name = realmObject.name
                    self.age = realmObject.age
                }
                public func toRealmObject() -> SampleObject {
                    return .init(id: id, name: name, age: age)
                }
            }
            """,
            macros: macros
        )
    }
    
    func test_EntityのメンバーにEntityが含まれている() throws {
        assertMacroExpansion(
            """
            @ObjectEntity(SampleObject.self)
            public struct SampleObjectEntity: Sendable {
                public let id: String
                @ObjectMember public let hoge: HogeObjectEntity?
            }
            """,
            expandedSource: """
            public struct SampleObjectEntity: Sendable {
                public let id: String
                @ObjectMember public let hoge: HogeObjectEntity?
            }
            
            extension SampleObjectEntity: BaseRealmEntity {
                public typealias RealmObject = SampleObject
                public init(realmObject: SampleObject) {
                    self.id = realmObject.id
                    if let hoge = realmObject.hoge {
                        self.hoge = .init(realmObject: hoge)
                    }
                }
                public func toRealmObject() -> SampleObject {
                    return .init(id: id, hoge: hoge?.toRealmObject())
                }
            }
            """,
            macros: macros
        )
    }
}
