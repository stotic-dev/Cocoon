//
//  CocoonMacros.swift
//  Cocoon
//
//  Created by 佐藤汰一 on 2025/06/23.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct CocoonMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ObjectMemberMacro.self,
        ObjectMacro.self,
        ObjectEntityMacro.self
    ]
}
