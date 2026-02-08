//
//  Item.swift
//  inputswitch
//
//  Created by 苏卫东 on 2026/2/8.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
