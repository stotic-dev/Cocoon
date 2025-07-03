//
//  ObjectEntityArgs.swift
//  Cocoon
//
//  Created by 佐藤汰一 on 2025/07/03.
//

import SwiftSyntax
import SwiftSyntaxMacros

struct ObjectEntityArgs {
    let arguments: LabeledExprListSyntax?
    
    var realmObjectType: TokenSyntax? {
        return arguments?
            .first?
            .expression.cast(MemberAccessExprSyntax.self)
            .base?.as(DeclReferenceExprSyntax.self)?
            .baseName
    }
}
