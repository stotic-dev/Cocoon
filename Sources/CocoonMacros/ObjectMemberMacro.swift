//
//  ObjectMemberMacro.swift
//  Cocoon
//
//  Created by 佐藤汰一 on 2025/06/28.
//

import SwiftSyntax
import SwiftSyntaxMacros

public struct ObjectMemberMacro: PeerMacro {
        
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return []
    }
}
