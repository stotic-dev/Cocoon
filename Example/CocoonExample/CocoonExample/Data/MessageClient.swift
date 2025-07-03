//
//  MessageClient.swift
//  CocoonExample
//
//  Created by 佐藤汰一 on 2025/07/01.
//

import Cocoon
import SwiftUI

struct MessageClient {
    let fetch: () async -> [MessageObjectEntity]
    let save: (MessageObjectEntity) async -> Void
}

extension EnvironmentValues {
    static let realm = RealmFactory.create(url: .applicationDirectory, version: 1)
    @Entry var messageClient: MessageClient = .init {
        do {
            return try await realm.value.read()
        }
        catch {
            print("error: \(error)")
            return []
        }
    } save: { input in
        do {
            _ = try await realm.value.insert(records: [input])
        }
        catch {
            print("error: \(error)")
        }
    }
}
