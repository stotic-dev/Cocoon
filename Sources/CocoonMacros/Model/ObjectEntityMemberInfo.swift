//
//  ObjectEntityMemberInfo.swift
//  Cocoon
//
//  Created by 佐藤汰一 on 2025/07/03.
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
