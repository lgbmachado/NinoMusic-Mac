//
//  ServerInfoRemote.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 05/10/23.
//

import Foundation

struct ServerInfoRemote: Encodable{
    let server_name: String?
    let music_count: String?
    let last_update: String?
}
