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
    
    convenience init(id: UUID, message: String) {
        self.init()
        self.id = id
        self.message = message
    }
}

//extension MessageObject {
//    typealias EntityType = MessageObjectEntity
//    struct MessageObjectEntity: Sendable {
//        typealias RealmObject = MessageObject
//        let id: UUID
//        let message: String
//    }
//}
//
//extension MessageObject.MessageObjectEntity: BaseRealmEntity {
//    init(realmObject: MessageObject) {
//        self.id = realmObject.id
//        self.message = realmObject.message
//    }
//    func toRealmObject() -> MessageObject {
//        return .init(id: id, message: message)
//    }
//}

typealias MessageEntity = MessageObject.MessageObjectEntity
