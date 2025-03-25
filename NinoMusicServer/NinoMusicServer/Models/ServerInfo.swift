//
//  ServerInfo.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 05/10/23.
//

import Foundation

struct ServerInfo: Encodable {
    let server_name: String?
    let music_count: Int?
    let last_update: String?
}
