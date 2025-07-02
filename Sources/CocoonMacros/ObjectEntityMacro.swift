//
//  ObjectEntityMacro.swift
//  Cocoon
//
//  Created by 佐藤汰一 on 2025/06/28.
//

import SwiftSyntax
import SwiftSyntaxMacros

struct ObjectEntityMemberInfo {
    let objectMemberInfo: ObjectMemberInfo
    let propertyName: String
    
    init?(variable: VariableDeclSyntax) {
        guard let propertyName = variable.bindings.first?.pattern.cast(IdentifierPatternSyntax.self).identifier.text else {
            
            return nil
        }
        self.propertyName = propertyName
        objectMemberInfo = ObjectMemberInfo(variable: variable)
    }
}

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



public struct ObjectEntityMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        // 引数からrealmObjectTypeNameを取得
        
        let arguments = ObjectEntityArgs(
            arguments: node.arguments?.as(LabeledExprListSyntax.self)
        )
        guard let objectType = arguments.realmObjectType else {
            throw MacroExpansionErrorMessage("RealmSwift.Objectの型をパラメータに設定してください。")
        }
        let realmObjectType = IdentifierTypeSyntax(name: objectType)
        
        let memberInfoList: [ObjectEntityMemberInfo] = declaration
            .memberBlock
            .members
            .compactMap {
                guard let variable = $0.decl.as(VariableDeclSyntax.self) else { return nil }
                return ObjectEntityMemberInfo(variable: variable)
            }
        
        let isPublic = declaration.isPublic
        
        return [
            ExtensionDeclSyntax(
                extendedType: type,
                inheritanceClause: .init(
                    colon: .colonToken(),
                    inheritedTypes: InheritedTypeListSyntax([
                        InheritedTypeSyntax(
                            type: IdentifierTypeSyntax(name: .identifier("BaseRealmEntity"))
                        )
                    ]))
            ) {
                TypeAliasDeclSyntax(
                    modifiers: isPublic ? [DeclModifierSyntax(name: .keyword(.public))] : [],
                    typealiasKeyword: .keyword(.typealias),
                    name: .identifier("RealmObject"),
                    initializer: TypeInitializerClauseSyntax(
                        equal: .equalToken(),
                        value: IdentifierTypeSyntax(name: objectType)
                    )
                )
                getEntityInitializeDeclSyntax(
                    entityType: type.cast(IdentifierTypeSyntax.self).name,
                    realmObjectType: realmObjectType,
                    memberList: memberInfoList,
                    isPublic: isPublic
                )
                getRealmConvertFunctionDeclSyntax(
                    realmObjectType: realmObjectType,
                    memberList: memberInfoList,
                    isPublic: isPublic
                )
            }
        ]
    }
}

private extension ObjectEntityMacro {
    static func getEntityInitializeDeclSyntax(
        entityType: TokenSyntax,
        realmObjectType: IdentifierTypeSyntax,
        memberList: [ObjectEntityMemberInfo],
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
                    if $0.objectMemberInfo.isObjectMember {
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
    
    static func getInitializeCode(memberVariableName valName: String) -> CodeBlockItemSyntax {
        return CodeBlockItemSyntax(
            item: .init(
                SequenceExprSyntax(elements: ExprListSyntax([
                    MemberAccessExprSyntax(
                        base: DeclReferenceExprSyntax(baseName: .keyword(.self)),
                        period: .periodToken(),
                        declName: DeclReferenceExprSyntax(baseName: .identifier(valName))
                    ),
                    AssignmentExprSyntax(equal: .equalToken()),
                    MemberAccessExprSyntax(
                        base: DeclReferenceExprSyntax(baseName: .identifier("realmObject")),
                        period: .periodToken(),
                        declName: DeclReferenceExprSyntax(baseName: .identifier(valName))
                    )
                ]))
            )
        )
    }
    
    static func getObjectMemberInitializeCode(memberInfo: ObjectEntityMemberInfo) -> CodeBlockItemSyntax {
        return CodeBlockItemSyntax(
            item: .init(
                ExpressionStmtSyntax(expression: IfExprSyntax(
                    ifKeyword: .keyword(.if),
                    conditions: ConditionElementListSyntax {
                        ConditionElementSyntax(
                            condition: .init(OptionalBindingConditionSyntax(
                                bindingSpecifier: .keyword(.let),
                                pattern: IdentifierPatternSyntax(identifier: .identifier(memberInfo.propertyName)),
                                initializer: InitializerClauseSyntax(
                                    equal: .equalToken(),
                                    value: MemberAccessExprSyntax(
                                        base: DeclReferenceExprSyntax(baseName: .identifier("realmObject")),
                                        period: .periodToken(),
                                        declName: DeclReferenceExprSyntax(baseName: .identifier(memberInfo.propertyName))
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
                                        declName: .init(baseName: .identifier(memberInfo.propertyName))
                                    )
                                    AssignmentExprSyntax(equal: .equalToken())
                                    FunctionCallExprSyntax(
                                        calledExpression: getObjectTokenType(objectMemberInfo: memberInfo.objectMemberInfo),
                                        leftParen: .leftParenToken(),
                                        arguments: [
                                            LabeledExprSyntax(
                                                label: .identifier("realmObject"),
                                                colon: .colonToken(),
                                                expression: DeclReferenceExprSyntax(baseName: .identifier(memberInfo.propertyName))
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
        memberList: [ObjectEntityMemberInfo],
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
                                        objectEntityInfo: $1,
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
    
    static func getConvertRealmFunctionArgumentsSyntax(objectEntityInfo: ObjectEntityMemberInfo, memberCount: Int, index: Int) -> LabeledExprSyntax {
        let expression: ExprSyntaxProtocol = if objectEntityInfo.objectMemberInfo.isObjectMember {
            FunctionCallExprSyntax(
                calledExpression: MemberAccessExprSyntax(
                    base: DeclReferenceExprSyntax(baseName: .identifier(objectEntityInfo.propertyName)),
                    period: .periodToken(),
                    name: .identifier("toRealmObject")
                ),
                leftParen: .leftParenToken(),
                arguments: [],
                rightParen: .rightParenToken()
            )
        }
        else {
            DeclReferenceExprSyntax(baseName: .identifier(objectEntityInfo.propertyName))
        }
        return LabeledExprSyntax(
            label: .identifier(objectEntityInfo.propertyName),
            colon: .colonToken(),
            expression: expression,
            trailingComma: index + 1 < memberCount ? .commaToken() : nil
        )
    }
}
