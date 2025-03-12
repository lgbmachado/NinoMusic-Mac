//
//  Log.swift
//  ServerLog
//
//  Created by Luiz Guilherme Machado on 28/02/25.
//

import Foundation

enum ServerLogType {
    case info
    case warning
    case error
    
    var iconName: String {
        switch self {
        case .info:
            "info.circle.fill"
        case .warning:
            "exclamationmark.triangle.fill"
        case .error:
            "xmark.circle.fill"
        }
    }
}

struct ServerLog: Identifiable, Equatable {
    let id = UUID()
    let dateTime: Date
    let type: ServerLogType
    let descr: String
}

