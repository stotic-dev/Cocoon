//
//  ObjectMemberInfo.swift
//  Cocoon
//
//  Created by 佐藤汰一 on 2025/06/30.
//

import SwiftSyntax

struct ObjectMemberInfo {
    let isObjectMember: Bool
    let type: TypeSyntax
    
    init(variable: VariableDeclSyntax) {
        isObjectMember = variable.attributes.contains {
            guard let attribute = $0.as(AttributeSyntax.self),
                  attribute.attributeName.cast(IdentifierTypeSyntax.self).name.text == "ObjectMember" else { return false }
            return true
        }
        
        guard let type = variable.bindings.first?.typeAnnotation?.type else {
            fatalError("Not found type syntax.")
        }
        self.type = type
    }
    
    var memberType: MemberTypeSyntax? {
        guard let optional = type.as(OptionalTypeSyntax.self) else {
            return type.as(MemberTypeSyntax.self)
        }
        return optional.wrappedType.as(MemberTypeSyntax.self)
    }
    
    var memberBaseType: IdentifierTypeSyntax? {
        guard let memberType = memberType else { return nil }
        return memberType.baseType.as(IdentifierTypeSyntax.self)
    }
    
    var memberDeclType: IdentifierTypeSyntax? {
        guard let memberType = memberType else { return nil }
        return .init(name: memberType.name)
    }
    
    var identifierType: IdentifierTypeSyntax? {
        guard let optional = type.as(OptionalTypeSyntax.self) else {
            return type.as(IdentifierTypeSyntax.self)
        }
        return optional.wrappedType.as(IdentifierTypeSyntax.self)
    }
}
