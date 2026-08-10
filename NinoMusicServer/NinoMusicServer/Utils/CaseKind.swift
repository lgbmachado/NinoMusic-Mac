//
//  CaseKind.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Baptista Machado on 03/08/26.
//

enum CaseKind: String, CaseIterable {
    case lowercase = "lowercase"
    case uppercase = "uppercase"
    case capitalized = "capitalized"
    case none = "none"
    
    var description: String {
        switch self {
        case .lowercase:
            return "minúsculas"
        case .uppercase:
            return "MAIÚSCULAS"
        case .capitalized:
            return "Primeira Letra Maiúscula"
        case .none:
            return "Sem alteração"
        }
    }
    
    static var allDescriptions: [String] {
        allCases.map { $0.description }
    }
}
