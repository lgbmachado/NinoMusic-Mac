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
    
    static let example = ServerLog(dateTime: Date.now,
                                   type: .info,
                                   descr: "Servidor iniciado com sucesso!")
    
    static let examples = [
        ServerLog(dateTime: Date.now,
                  type: .info,
                  descr: "Servidor iniciado com sucesso!"),
        
        ServerLog(dateTime: Date.now,
                  type:  .warning,
                  descr: "Música não encontrada!"),
        ServerLog(dateTime: Date.now,
                  type:  .error,
                  descr: "Falha ao iniciar o versidos!")
    ]
}

