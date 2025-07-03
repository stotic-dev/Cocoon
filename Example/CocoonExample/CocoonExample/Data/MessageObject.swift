//
//  MessageObject.swift
//  CocoonExample
//
//  Created by 佐藤汰一 on 2025/07/01.
//

import Cocoon
import Foundation
import RealmSwift

@Object
final class MessageObject: Object {
    @Persisted(primaryKey: true) var id: UUID
    @Persisted var message: String
}

@ObjectEntity(MessageObject.self)
struct MessageObjectEntity: Sendable {
    let id: UUID
    let message: String
}
