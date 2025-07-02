//
//  EntityMember.swift
//  Cocoon
//
//  Created by 佐藤汰一 on 2025/06/30.
//

import SwiftSyntax
import SwiftSyntaxMacros

struct EntityMember {
    let propertyName: TokenSyntax
    let pattern: PatternSyntax
    let typeAnnotation: TypeAnnotationSyntax
    let objectMemberType: ObjectMemberInfo
    let attributes: AttributeListSyntax
    
    var isObjectMember: Bool { objectMemberType.isObjectMember }
    
    init?(variable: VariableDeclSyntax) throws {
        guard variable.attributes.contains(where: {
            guard let identifier = $0.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name else {
                return false
            }
            return identifier.text == "Persisted"
        })
        else { return nil }
        
        guard let pattern = variable.bindings.first?.pattern,
              let typeAnnotation = variable.bindings.first?.typeAnnotation
        else {
            throw MacroExpansionErrorMessage("")
        }
        
        self.propertyName = pattern.cast(IdentifierPatternSyntax.self).identifier
        self.pattern = pattern
        self.typeAnnotation = typeAnnotation
        self.objectMemberType = .init(variable: variable)
        self.attributes = variable.attributes
    }
    
    func createVariableDeclSyntax(isPublic: Bool) -> VariableDeclSyntax {
        let typeAnnotation = if objectMemberType.isObjectMember {
            getObjectMemberTypeAnnotation()
        }
        else {
            typeAnnotation
        }
        return VariableDeclSyntax(
            attributes: getVariableAttributes(),
            modifiers: isPublic ? [DeclModifierSyntax(name: .keyword(.public))] : [],
            bindingSpecifier: .keyword(.let),
            bindings: [
                .init(
                    pattern: pattern,
                    typeAnnotation: typeAnnotation
                )
            ]
        )
    }
}

private extension EntityMember {
    func getVariableAttributes() -> AttributeListSyntax {
        if objectMemberType.isObjectMember,
           let attribute = attributes.first?.cast(AttributeSyntax.self) {
            return [.init(attribute)]
        }
        else {
            return []
        }
    }
    
    func getObjectMemberTypeAnnotation() -> TypeAnnotationSyntax {
        if let optionalType = typeAnnotation.type.as(OptionalTypeSyntax.self) {
            return TypeAnnotationSyntax(
                type: OptionalTypeSyntax(
                    wrappedType: MemberTypeSyntax(
                        baseType: optionalType.wrappedType,
                        name: .identifier("EntityType")
                    )
                )
            )
        }
        else {
            return TypeAnnotationSyntax(
                type: MemberTypeSyntax(
                    baseType: typeAnnotation.type,
                    name: .identifier("EntityType")
                )
            )
        }
    }
}
