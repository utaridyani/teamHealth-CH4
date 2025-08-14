//
//  Item.swift
//  teamHealth
//
//  Created by Utari Dyani Laksmi on 14/08/25.
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
