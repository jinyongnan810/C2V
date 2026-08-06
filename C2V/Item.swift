//
//  Item.swift
//  C2V
//
//  Created by Yuunan kin on 2026/08/06.
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
