//
//  MessageClient.swift
//  CocoonExample
//
//  Created by 佐藤汰一 on 2025/07/01.
//

import Combine
import Cocoon
import SwiftUI

struct MessageClient {
    let fetch: () async -> [Message]
    let save: (Message) async -> Void
    let delete: (Message) async -> Void
    let update: (Message) async -> Void
    let observe: () async -> AnyPublisher<[Message], Never>
}

extension EnvironmentValues {
    private static let realm = RealmStore().getRealm()
    
    @Entry var messageClient: MessageClient = .init {
        let messages: [MessageObjectEntity] = await realm.value.read()
        return messages.map { .init(id: $0.id.uuidString, text: $0.message) }
    } save: { input in
        guard let entity = MessageObjectEntity(message: input) else { return }
        _ = await realm.value.insert(records: [entity])
    } delete: { target in
        _ = await realm.value.delete { (entity: MessageObjectEntity) in
            entity.id.uuidString == target.id
        }
    } update: { updateData in
        guard let updateEntity = MessageObjectEntity(message: updateData) else { return }
        _ = await realm.value.update(
            type: MessageObjectEntity.self,
            value: ["id": updateEntity.id, "message": updateEntity.message]
        )
    } observe: {
        return await realm.value
            .readObjectsForObserve(type: MessageObjectEntity.self)
            .map { $0.map { Message(id: $0.id.uuidString, text: $0.message) } }
            .eraseToAnyPublisher()
    }
    
    static let previewMessageClient: MessageClient = .init(
        fetch: {
            return [
                .init(id: "id", text: "Test")
            ]
        }, save: {
            print("Saved: \($0)")
        }, delete: {
            print("Delete: \($0)")
        }, update: {
            print("Update: \($0)")
        }, observe: {
            PassthroughSubject().eraseToAnyPublisher()
        }
    )
}

final class RealmStore: Sendable {
    
    static let shared = RealmStore()
    
    private let realm: Task<RealmWrapper, Error>
    
    init() {
        
        let dir = URL.applicationSupportDirectory
        if !FileManager.default.fileExists(atPath: dir.path()) {
            
            do {
                
                try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            }
            catch {
                
                print("Failed create directory: \(dir)")
            }
        }
        
        realm = RealmFactory.create(url: dir.appending(path: "db.realm"), version: 1)
    }
    
    func getRealm() -> Task<RealmWrapper, Never> {
        
        return Task {
            do {
                
                return try await realm.value
            }
            catch {
                
                preconditionFailure("Failed create realm: \(error)")
            }
        }
    }
}
