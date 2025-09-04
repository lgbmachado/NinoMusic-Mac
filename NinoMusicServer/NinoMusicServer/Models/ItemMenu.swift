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
    case artists
    case albuns
    case tags
    case server
    
    var id: String {
        switch self {
        case .libray:
            "libray"
        case .musics:
            "musics"
        case .artists:
            "artists"
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
        case .artists:
            "Artistas"
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
        case .artists:
            "music.microphone"
        case .albuns:
            "opticaldisc"
        case .tags:
            "tag"
        case .server:
            "server.rack"
        }
    }
    
    static var menu: [ItemMenu] {
        [.libray, .musics, .artists, .albuns, .tags, .server]
    }
}
