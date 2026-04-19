//
//  Insight.swift
//  ExpanseTracker
//
//  Created by Shivanand Koli on 19/04/26.
//
import Foundation
import SwiftUI

enum InsightType {
    case info
    case warning
    case positive
}

struct Insight: Identifiable {
    let id = UUID()
    let message: String
    let type: InsightType
}
