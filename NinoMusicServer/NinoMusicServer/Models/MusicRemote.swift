//
//  MusicRemote.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 30/09/23.
//

import Foundation

struct MusicRemote: Encodable{
    let id: Int?
    let artist: String?
    let album: String?
    let year: String?
    let track: Int?
    let musicTitle: String?
    let genre: String?
    let duration: Int?
}
