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
    let propertyType: TypeSyntax
    let objectMemberType: ObjectMemberInfo
    
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
        self.propertyType = typeAnnotation.type
        self.objectMemberType = .init(variable: variable)
    }
}
