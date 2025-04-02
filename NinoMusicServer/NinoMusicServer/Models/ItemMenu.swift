//
//  ItemMenu.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 25/02/25.
//

import Foundation

enum ItemMenu: Identifiable, CaseIterable, Hashable {
        
    case libray
    case musics
    case albuns
    case tags
    case server
    
    var id: String {
        switch self {
        case .libray:
            "libray"
        case .musics:
            "musics"
        case .albuns:
            "albuns"
        case .tags:
            "tags"
        case .server:
            "server"
        }
    }
    
    var displayName: String {
        switch self {
        case .libray:
            "Biblioteca"
        case .musics:
            "Músicas"
        case .albuns:
            "Albuns"
        case .tags:
            "Editor de Tags"
        case .server:
            "Servidor de Músicas"
        }
    }
    
    var iconName: String {
        switch self {
        case .libray:
            "folder"
        case .musics:
            "music.note.list"
        case .albuns:
            "opticaldisc"
        case .tags:
            "tag"
        case .server:
            "server.rack"
        }
    }
    
    static var menu: [ItemMenu] {
        [.libray, .musics, .albuns, .tags, .server]
    }
}
