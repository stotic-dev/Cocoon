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
                typealias RealmObject = SampleObject
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
    
    func test_Entityのメンバーがプリミティブ型のみ() throws {
        assertMacroExpansion(
            """
            public extension SampleObject {
                @ObjectEntity
                public struct SampleObjectEntity: Sendable {
                    typealias RealmObject = SampleObject
                    let id: String
                    let name: String
                    let age: Int
                }
            }
            """,
            expandedSource: """
            public extension SampleObject {
                public struct SampleObjectEntity: Sendable {
                    typealias RealmObject = SampleObject
                    let id: String
                    let name: String
                    let age: Int
                }
            }
            
            public extension SampleObject.SampleObjectEntity: BaseRealmEntity {
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
            public extension SampleObject {
                typealias EntityType = SampleObjectEntity
                @ObjectEntity
                public struct SampleObjectEntity: Sendable {
                    typealias RealmObject = SampleObject
                    public let id: String
                    @ObjectMember public let hoge: HogeObject.EntityType?
                }
            }
            """,
            expandedSource: """
            public extension SampleObject {
                typealias EntityType = SampleObjectEntity
                public struct SampleObjectEntity: Sendable {
                    typealias RealmObject = SampleObject
                    public let id: String
                    @ObjectMember public let hoge: HogeObject.EntityType?
                }
            }
            
            public extension SampleObject.SampleObjectEntity: BaseRealmEntity {
                public init(realmObject: SampleObject) {
                    self.id = realmObject.id
                    if let hoge = realmObject.hoge {
                        self.hoge = HogeObject.EntityType(realmObject: hoge)
                    }
                }
                public func toRealmObject() -> SampleObject {
                    return .init(id: id, hoge: hoge.toRealmObject())
                }
            }
            """,
            macros: macros
        )
    }
}
