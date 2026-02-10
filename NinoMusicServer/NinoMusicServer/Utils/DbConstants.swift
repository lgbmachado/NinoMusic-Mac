//
//  DbConstants.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 05/09/25.
//

import Foundation

struct DbConstants {
    
//    static let databasePath = (Bundle.main.bundlePath as NSString).deletingLastPathComponent + "/MusicDatabase.db"
    static let databasePath = "/Users/nino/NinoMusic.sqlite"

    struct TableAlbum {
        static let tableName = "Albuns"
        static let colRowId = "rowid"
        static let colAlbum = "Album"
        static let colYear = "Year"
    }

    struct TableArtist {
        static let tableName = "Artists"
        static let colRowId = "rowid"
        static let colArtist = "Artist"
    }
    
    struct TableDiretory {
        static let tableName = "Directories"
        static let colRowId = "rowid"
        static let colDirName = "Name"
        static let colDirPath = "DirPath"
        static let colMusicsCount = "MusicsCount"
        static let colTotalTime = "TotalTime"
    }
    
    struct TableGenre {
        static let tableName = "Genres"
        static let colRowId = "rowid"
        static let colGenre = "Genre"
    }

    struct TableMusic {
        static let tableName = "Musics"
        static let colRowId = "rowid"
        static let colTitle = "Title"
        static let colIdArtist = "IdArtist"
        static let colIdAlbum = "IdAlbum"
        static let colTrack = "Track"
        static let colIdGenre = "IdGenre"
        static let colDuration = "Duration"
        static let colFilePath = "FilePath"
        static let colHasLyrics = "HasLyrics"
    }
}
