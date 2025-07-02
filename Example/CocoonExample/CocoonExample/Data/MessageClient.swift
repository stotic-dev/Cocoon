//
//  MessageClient.swift
//  CocoonExample
//
//  Created by 佐藤汰一 on 2025/07/01.
//

import Cocoon
import SwiftUI

struct MessageClient {
    let fetch: () async -> [MessageEntity]
    let save: (MessageEntity) async -> Void
}

extension MessageClient: EnvironmentKey {
    static let realm = RealmFactory.create(url: .applicationDirectory, version: 1)
    static let defaultValue: MessageClient = .init {
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

extension EnvironmentValues {
    var messageClient: MessageClient {
        get { self[MessageClient.self] }
        set { self[MessageClient.self] = newValue }
    }
}
