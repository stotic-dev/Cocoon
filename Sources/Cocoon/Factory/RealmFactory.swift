//
//  RealmFactory.swift
//  MachoFramework
//
//  Created by 佐藤汰一 on 2024/11/28.
//

import Foundation
import RealmSwift

public struct RealmFactory {
    
    public static func create(url: URL, version: UInt64) -> Task<RealmWrapper, Error> {
        
        return Task {
            let configuration = Realm.Configuration(fileURL: url,
                                                    schemaVersion: version)
            let realm = try await Realm(configuration: configuration, actor: RealmActor.shared)
            return await RealmWrapper(realm)
        }
    }
    
    public static func create(onMemory id: String, version: UInt64) -> Task<RealmWrapper, Error> {
        
        return Task {
            let configuration = Realm.Configuration(inMemoryIdentifier: id,
                                                    schemaVersion: version)
            let realm = try await Realm(configuration: configuration, actor: RealmActor.shared)
            return await RealmWrapper(realm)
        }
    }
}
