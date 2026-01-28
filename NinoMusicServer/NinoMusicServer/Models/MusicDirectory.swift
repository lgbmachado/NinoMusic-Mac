//
//  MusicDirectory.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 05/08/24.
//

import Foundation
import SwiftData

@Model
final class MusicDirectory {
    @Attribute(.unique) var id: UUID
    var name: String
    var path: String
    var musicCount: Int
    var totalTime: TimeInterval
    
    init(id: UUID = UUID(), name: String = "", path: String = "", musicCount: Int = 0, totalTime: TimeInterval = 0) {
        self.id = id
        self.name = name
        self.path = path
        self.musicCount = musicCount
        self.totalTime = totalTime
    }
}
