//
//  ObjectMacro.swift
//  Cocoon
//
//  Created by 佐藤汰一 on 2025/06/22.
//

import SwiftSyntax
import SwiftSyntaxMacros

public struct ObjectMacro: ExtensionMacro {
    
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo protocols: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        let members: [MemberBlockItemSyntax] = declaration.memberBlock.members.map(\.self)
        let variablesMember = members.compactMap { $0.decl.as(VariableDeclSyntax.self) }
        
        let isPublic = declaration.isPublic
        var modifiers: DeclModifierListSyntax = []
        if declaration.isPublic {
            modifiers.append(.init(name: .keyword(.public)))
        }
        modifiers.append(.init(name: .keyword(.convenience)))
        
        let entityMember: [EntityMember] = try variablesMember.compactMap {
            return try EntityMember(variable: $0)
        }
                
        return [
            ExtensionDeclSyntax(
                extendedType: type
            ) {
                MemberBlockItemSyntax(decl: InitializerDeclSyntax(
                    modifiers: modifiers,
                    signature: FunctionSignatureSyntax(
                        parameterClause: FunctionParameterClauseSyntax(
                            leftParen: .leftParenToken(),
                            parameters: FunctionParameterListSyntax(
                                entityMember.enumerated().map {
                                    FunctionParameterSyntax(
                                        firstName: $1.propertyName,
                                        colon: .colonToken(),
                                        type: $1.propertyType,
                                        trailingComma: $0 + 1 < entityMember.count ? .commaToken() : nil
                                    )
                                }
                            ),
                            rightParen: .rightParenToken()
                        )
                    ),
                    body: CodeBlockSyntax(
                        leftBrace: .leftBraceToken(),
                        statements: [
                            CodeBlockItemSyntax(
                                item: .init(
                                    FunctionCallExprSyntax(
                                        calledExpression: MemberAccessExprSyntax(
                                            base: DeclReferenceExprSyntax(baseName: .keyword(.`self`)),
                                            period: .periodToken(),
                                            name: .keyword(.`init`)
                                        ),
                                        leftParen: .leftParenToken(),
                                        arguments: [],
                                        rightParen: .rightParenToken()
                                    )
                                )
                            )
                        ] + CodeBlockItemListSyntax(entityMember.map {
                            getInitializeCodeItem(propertyName: $0.propertyName)
                        }),
                        rightBrace: .rightBraceToken()
                    )
                ))
            }
        ]
    }
}

private extension ObjectMacro {
    
    static func getInitializeCodeItem(propertyName valName: TokenSyntax) -> CodeBlockItemSyntax {
        return CodeBlockItemSyntax(
            item: .init(
                SequenceExprSyntax(elements: ExprListSyntax([
                    MemberAccessExprSyntax(
                        base: DeclReferenceExprSyntax(baseName: .keyword(.self)),
                        period: .periodToken(),
                        declName: DeclReferenceExprSyntax(baseName: valName)
                    ),
                    AssignmentExprSyntax(equal: .equalToken()),
                    DeclReferenceExprSyntax(baseName: valName)
                ]))
            )
        )
    }
}
