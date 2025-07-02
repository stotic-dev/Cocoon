//
//  DeclGroupSyntax+Extension.swift
//  Cocoon
//
//  Created by 佐藤汰一 on 2025/06/28.
//

import SwiftSyntax

extension DeclGroupSyntax {
    var isPublic: Bool {
        return self.modifiers.contains { $0.name.text == "public" }
    }
}
