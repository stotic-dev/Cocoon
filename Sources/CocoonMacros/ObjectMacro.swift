//
//  ObjectMacro.swift
//  Cocoon
//
//  Created by 佐藤汰一 on 2025/06/22.
//

import SwiftSyntax
import SwiftSyntaxMacros

public struct ObjectMacro: ExtensionMacro {
    static let entityTypeAliasName = "EntityType"
    
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
        let entityMember: [EntityMember] = try variablesMember.compactMap {
            return try EntityMember(variable: $0)
        }
                
        return [
            ExtensionDeclSyntax(
                modifiers: isPublic ? [DeclModifierSyntax(name: .keyword(.public))] : [],
                extendedType: type
            ) {
                getEntityTypeAliasDeclSyntax(type: type)
                getEntityStructDeclSyntax(
                    isPublic: isPublic,
                    type: type,
                    entityMember: entityMember.map { MemberBlockItemSyntax(decl: $0.createVariableDeclSyntax(isPublic: isPublic)) }
                )
            },
            ExtensionDeclSyntax(
                extendedType: MemberTypeSyntax(
                    baseType: type,
                    name: .identifier(getEntityTypeName(objectType: type))
                ),
                inheritanceClause: .init(
                    colon: .colonToken(),
                    inheritedTypes: InheritedTypeListSyntax([
                        InheritedTypeSyntax(
                            type: IdentifierTypeSyntax(name: .identifier("BaseRealmEntity"))
                        )
                    ]))
            ) {
                getEntityInitializeDeclSyntax(
                    entityType: .identifier(getEntityTypeName(objectType: type)),
                    realmObjectType: type.cast(IdentifierTypeSyntax.self),
                    memberList: entityMember,
                    isPublic: isPublic
                )
                getRealmConvertFunctionDeclSyntax(
                    realmObjectType: type.cast(IdentifierTypeSyntax.self),
                    memberList: entityMember,
                    isPublic: isPublic
                )
            }
        ]
    }
}

private extension ObjectMacro {
    static func getEntityTypeName(objectType: some TypeSyntaxProtocol) -> String {
        return "\(objectType.cast(IdentifierTypeSyntax.self).name.text)Entity"
    }
    
    static func getEntityTypeAliasDeclSyntax(type: some TypeSyntaxProtocol) -> TypeAliasDeclSyntax {
        return TypeAliasDeclSyntax(
            typealiasKeyword: .keyword(.typealias),
            name: .identifier("EntityType"),
            initializer: TypeInitializerClauseSyntax(
                equal: .equalToken(),
                value: IdentifierTypeSyntax(name: .identifier(getEntityTypeName(objectType: type)))
            )
        )
    }
    
    static func getEntityStructDeclSyntax(
        isPublic: Bool,
        type: some TypeSyntaxProtocol,
        entityMember: [MemberBlockItemSyntax]
    ) -> StructDeclSyntax {
        let typeAliasDecl = TypeAliasDeclSyntax(
            modifiers: isPublic ? [DeclModifierSyntax(name: .keyword(.public))] : [],
            typealiasKeyword: .keyword(.typealias),
            name: .identifier("RealmObject"),
            initializer: TypeInitializerClauseSyntax(
                equal: .equalToken(),
                value: type.cast(IdentifierTypeSyntax.self)
            )
        )
        
        return StructDeclSyntax(
//            attributes: [
//                .init(.init(
//                    atSign: .atSignToken(),
//                    attributeName: IdentifierTypeSyntax(name: "ObjectEntity"),
//                    trailingTrivia: .newline
//                ))
//            ],
            structKeyword: .keyword(.struct),
            name: .identifier(getEntityTypeName(objectType: type)),
            inheritanceClause: InheritanceClauseSyntax(inheritedTypes: [
                .init(type: IdentifierTypeSyntax(name: "Sendable"))
            ]),
            memberBlock: MemberBlockSyntax(
                leftBrace: .leftBraceToken(),
                members: MemberBlockItemListSyntax([
                    MemberBlockItemSyntax(decl: typeAliasDecl)
                ] + entityMember),
                rightBrace: .rightBraceToken()
            )
        )
    }
    
    static func getEntityInitializeDeclSyntax(
        entityType: TokenSyntax,
        realmObjectType: IdentifierTypeSyntax,
        memberList: [EntityMember],
        isPublic: Bool
    ) -> MemberBlockItemSyntax {
        MemberBlockItemSyntax(decl: InitializerDeclSyntax(
            modifiers: isPublic ? [DeclModifierSyntax(name: .keyword(.public))] : [],
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(
                    leftParen: .leftParenToken(),
                    parameters: FunctionParameterListSyntax([
                        FunctionParameterSyntax(
                            firstName: .identifier("realmObject"),
                            colon: .colonToken(),
                            type: realmObjectType
                        )
                    ]),
                    rightParen: .rightParenToken()
                )
            ),
            body: CodeBlockSyntax(
                leftBrace: .leftBraceToken(),
                statements: CodeBlockItemListSyntax(memberList.map {
                    if $0.isObjectMember {
                        getObjectMemberInitializeCode(memberInfo: $0)
                    }
                    else {
                        getInitializeCode(memberVariableName: $0.propertyName)
                    }
                }),
                rightBrace: .rightBraceToken()
            )
        ))
    }
    
    static func getInitializeCode(memberVariableName valName: TokenSyntax) -> CodeBlockItemSyntax {
        return CodeBlockItemSyntax(
            item: .init(
                SequenceExprSyntax(elements: ExprListSyntax([
                    MemberAccessExprSyntax(
                        base: DeclReferenceExprSyntax(baseName: .keyword(.self)),
                        period: .periodToken(),
                        declName: DeclReferenceExprSyntax(baseName: valName)
                    ),
                    AssignmentExprSyntax(equal: .equalToken()),
                    MemberAccessExprSyntax(
                        base: DeclReferenceExprSyntax(baseName: .identifier("realmObject")),
                        period: .periodToken(),
                        declName: DeclReferenceExprSyntax(baseName: valName)
                    )
                ]))
            )
        )
    }
    
    static func getObjectMemberInitializeCode(memberInfo: EntityMember) -> CodeBlockItemSyntax {
        return CodeBlockItemSyntax(
            item: .init(
                ExpressionStmtSyntax(expression: IfExprSyntax(
                    ifKeyword: .keyword(.if),
                    conditions: ConditionElementListSyntax {
                        ConditionElementSyntax(
                            condition: .init(OptionalBindingConditionSyntax(
                                bindingSpecifier: .keyword(.let),
                                pattern: IdentifierPatternSyntax(identifier: memberInfo.propertyName),
                                initializer: InitializerClauseSyntax(
                                    equal: .equalToken(),
                                    value: MemberAccessExprSyntax(
                                        base: DeclReferenceExprSyntax(baseName: .identifier("realmObject")),
                                        period: .periodToken(),
                                        declName: DeclReferenceExprSyntax(baseName: memberInfo.propertyName)
                                    )
                                )
                            ))
                        )
                    },
                    body: CodeBlockSyntax {
                        CodeBlockItemSyntax(
                            item: .init(SequenceExprSyntax(
                                elements: ExprListSyntax {
                                    MemberAccessExprSyntax(
                                        base: DeclReferenceExprSyntax(baseName: .keyword(.`self`)),
                                        period: .periodToken(),
                                        declName: .init(baseName: memberInfo.propertyName)
                                    )
                                    AssignmentExprSyntax(equal: .equalToken())
                                    FunctionCallExprSyntax(
                                        calledExpression: getObjectTokenType(objectMemberInfo: memberInfo.objectMemberType),
                                        leftParen: .leftParenToken(),
                                        arguments: [
                                            LabeledExprSyntax(
                                                label: .identifier("realmObject"),
                                                colon: .colonToken(),
                                                expression: DeclReferenceExprSyntax(baseName: memberInfo.propertyName)
                                            )
                                        ],
                                        rightParen: .rightParenToken()
                                    )
                                }
                            ))
                        )
                    }
                ))
            )
        )
    }
    
    static func getObjectTokenType(objectMemberInfo: ObjectMemberInfo) -> ExprSyntax {
        if let identifierType = objectMemberInfo.identifierType {
            return .init(DeclReferenceExprSyntax(baseName: identifierType.name))
        }
        else if let memberBaseType = objectMemberInfo.memberBaseType {
            return .init(
                MemberAccessExprSyntax(
                    base: DeclReferenceExprSyntax(
                        baseName: memberBaseType.name),
                    period: .periodToken(),
                    declName: .init(baseName: .identifier("EntityType"))
                )
            )
        }
        else {
            fatalError("Not unexpected type with @ObjectMember.")
        }
    }
    
    static func getRealmConvertFunctionDeclSyntax(
        realmObjectType: IdentifierTypeSyntax,
        memberList: [EntityMember],
        isPublic: Bool
    ) -> MemberBlockItemSyntax {
        MemberBlockItemSyntax(decl: FunctionDeclSyntax(
            modifiers: isPublic ? [DeclModifierSyntax(name: .keyword(.public))] : [],
            funcKeyword: .keyword(.func),
            name: .identifier("toRealmObject"),
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(
                    leftParen: .leftParenToken(),
                    parameters: FunctionParameterListSyntax([]),
                    rightParen: .rightParenToken()
                ),
                returnClause: ReturnClauseSyntax(
                    arrow: .arrowToken(),
                    type: realmObjectType
                )
            ),
            body: CodeBlockSyntax(
                leftBrace: .leftBraceToken(),
                statements: CodeBlockItemListSyntax([
                    CodeBlockItemSyntax(
                        item: .init(ReturnStmtSyntax(
                            returnKeyword: .keyword(.return),
                            expression: FunctionCallExprSyntax(
                                calledExpression: MemberAccessExprSyntax(
                                    period: .periodToken(),
                                    declName: DeclReferenceExprSyntax(baseName: .keyword(.`init`))
                                ),
                                leftParen: .leftParenToken(),
                                arguments: LabeledExprListSyntax(memberList.enumerated().map {
                                    getConvertRealmFunctionArgumentsSyntax(
                                        entityMember: $1,
                                        memberCount: memberList.count,
                                        index: $0
                                    )
                                }),
                                rightParen: .rightParenToken()
                            )
                        ))
                    )
                ])
            )
        ))
    }
    
    static func getConvertRealmFunctionArgumentsSyntax(entityMember: EntityMember, memberCount: Int, index: Int) -> LabeledExprSyntax {
        let expression: ExprSyntaxProtocol = if entityMember.isObjectMember {
            FunctionCallExprSyntax(
                calledExpression: MemberAccessExprSyntax(
                    base: DeclReferenceExprSyntax(baseName: entityMember.propertyName),
                    period: .periodToken(),
                    name: .identifier("toRealmObject")
                ),
                leftParen: .leftParenToken(),
                arguments: [],
                rightParen: .rightParenToken()
            )
        }
        else {
            DeclReferenceExprSyntax(baseName: entityMember.propertyName)
        }
        return LabeledExprSyntax(
            label: entityMember.propertyName,
            colon: .colonToken(),
            expression: expression,
            trailingComma: index + 1 < memberCount ? .commaToken() : nil
        )
    }
}
