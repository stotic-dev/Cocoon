//
//  CocoonMacro.swift
//  Cocoon
//
//  Created by 佐藤汰一 on 2025/06/22.
//

import CocoonCore
import RealmSwift

@attached(peer)
public macro ObjectMember() = #externalMacro(module: "CocoonMacros", type: "ObjectMemberMacro")

@attached(extension, conformances: BaseRealmEntity, names: arbitrary)
public macro Object() = #externalMacro(module: "CocoonMacros", type: "ObjectMacro")

@attached(extension, conformances: BaseRealmEntity, names: arbitrary)
public macro ObjectEntity(_ objectType: Object.Type) = #externalMacro(module: "CocoonMacros", type: "ObjectEntityMacro")
