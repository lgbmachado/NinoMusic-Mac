//
//  Music.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 05/08/24.
//

import Foundation

struct Music: Identifiable {
    let id = UUID()
    let artist: String
    let album: String
    let year: String
    let track: Int
    let musicTitle: String
    let genre: String
    let filePath: String
    
    static let example = Music(artist: "BEAR MCCREARY",
                               album: "BATTLESTAR GALACTICA - SEASON 3",
                               year: "2007",
                               track: 21,
                               musicTitle: "ALL ALONG THE WATCHTOWER",
                               genre: "INSTRUMENTAL/CLÁSSICO",
                               filePath: "/Users/nino/Documents/XCode/_musicas/BEAR MCCREARY - ALL ALONG THE WATCHTOWER.MP3")
    
    static let examples = [
        Music(artist: "BEAR MCCREARY",
              album: "BATTLESTAR GALACTICA - SEASON 3",
              year: "2007",
              track: 21,
              musicTitle: "ALL ALONG THE WATCHTOWER",
              genre: "INSTRUMENTAL/CLÁSSICO",
              filePath: "/Users/nino/Documents/XCode/_musicas/BEAR MCCREARY - ALL ALONG THE WATCHTOWER.MP3"),
        
        Music(artist: "BARRY WHITE",
              album: "THE MAN",
              year: "1978",
              track: 6,
              musicTitle: "JUST THE WAY YOU ARE",
              genre: "POP",
              filePath: "/Users/nino/Documents/XCode/_musicas/BARRY WHITE - JUST THE WAY YOU ARE.MP3"),
        
        Music(artist: "BILLY PAUL",
              album: "ONLY THE STRONG SURVIVE",
              year: "1977",
              track: 1,
              musicTitle: "ONLY THE STRONG SURVIVE",
              genre: "POP",
              filePath: "/Users/nino/Documents/XCode/_musicas/BILLY PAUL - ONLY THE STRONG SURVIVE.MP3"),
        
        Music(artist: "BILLY PAUL",
              album: "ME AND MRS. JONES: THE BEST OF BILLY PAUL",
              year: "1999",
              track: 6,
              musicTitle: "YOUR SONG",
              genre: "POP",
              filePath: "/Users/nino/Documents/XCode/_musicas/BILLY PAUL - YOUR SONG.MP3"),
        
        Music(artist: "ALPHAVILLE",
              album: "FOREVER YOUNG (SPECIAL DANCE VERSION)",
              year: "1984",
              track: 1,
              musicTitle: "FOREVER YOUNG",
              genre: "POP",
              filePath: "/Users/nino/Documents/XCode/_musicas/ALPHAVILLE - FOREVER YOUNG.MP3"),
        
        Music(artist: "A-HA",
              album: "HUNTING HIGH AND LOW",
              year: "1985",
              track: 3,
              musicTitle: "HUNTING HIGH AND LOW",
              genre: "POP",
              filePath: "/Users/nino/Documents/XCode/_musicas/A-HA - HUNTING HIGH AND LOW.MP3"),
        
        Music(artist: "A-HA",
              album: "HUNTING HIGH AND LOW",
              year: "1985",
              track: 1,
              musicTitle: "TAKE ON ME",
              genre: "POP",
              filePath: "/Users/nino/Documents/XCode/_musicas/A-HA - TAKE ON ME.MP3"),
        
        Music(artist: "A-HA",
              album: "CAST IN STEEL",
              year: "2015",
              track: 1,
              musicTitle: "CAST IN STEEL",
              genre: "POP",
              filePath: "/Users/nino/Documents/XCode/_musicas/A-HA - CAST IN STEEL.MP3"),
        
    ]
    
    static func musicsExamples() -> [Music] {
        self.examples.sorted(by: {$0.musicTitle < $1.musicTitle})
    }
    
    static func artistExamples() -> [Music] {
        var lastArtist = ""
        var lastAlbum = ""
        var result = [Music]()
        for item in self.examples.sorted(by: {$0.artist < $1.artist}) {
            let music = Music(artist: item.artist != lastArtist ? item.artist : "",
                              album: item.album != lastAlbum ? item.album : "",
                              year: item.year,
                              track: item.track,
                              musicTitle: item.musicTitle,
                              genre: item.genre,
                              filePath: item.filePath)
            lastArtist = item.artist
            lastAlbum = item.album
            result.append(music)
        }
        return result
    }
    
    static func albumExamples() -> [Music] {
        var lastAlbum = ""
        var result = [Music]()
        for item in self.examples.sorted(by: {$0.album < $1.album}) {
            let music = Music(artist: item.artist,
                              album: item.album != lastAlbum ? item.album : "",
                              year: item.year,
                              track: item.track,
                              musicTitle: item.musicTitle,
                              genre: item.genre,
                              filePath: item.filePath)
            lastAlbum = item.album
            result.append(music)
        }
        return result
    }
}

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
