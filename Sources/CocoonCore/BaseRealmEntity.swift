//
//  BaseRealmEntity.swift
//  Cocoon
//
//  Created by 佐藤汰一 on 2025/07/01.
//

import RealmSwift

public protocol BaseRealmEntity: Equatable, Identifiable, Sendable {
    
    associatedtype RealmObject: Object
    
    /// RealmObject→Struct変換用イニシャライザ
    init(realmObject: RealmObject)
    
    /// Struct→RealmObject変換用のメソッド
    /// - Attention: RealmActorからのみ呼び出さないようにする
    func toRealmObject() -> RealmObject
}
