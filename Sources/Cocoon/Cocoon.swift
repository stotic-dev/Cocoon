//
//  Cocoon.swift
//  Cocoon
//
//  Created by 佐藤汰一 on 2025/07/01.
//

@_exported import CocoonMacro
@_exported import CocoonCore
@_exported import RealmSwift

import SwiftUI

struct SampleClient: Sendable {
    let fetch: @Sendable () async throws -> [SampleObjectEntity]
}

@available(macOS 13.0, *)
extension EnvironmentValues {
    static let realm = RealmFactory.create(url: .applicationDirectory, version: 1)
    @Entry var sampleClient: SampleClient = .init {
        return try await realm.value.read()
    }
}

public final class SampleObject: Object {
    @Persisted var id: String
    @Persisted var text: String
    
    convenience init(id: String, text: String) {
        self.init()
        self.id = id
        self.text = text
    }
}

@ObjectEntity(SampleObject.self)
public struct SampleObjectEntity: Sendable {
    public let id: String
    public let text: String
}
