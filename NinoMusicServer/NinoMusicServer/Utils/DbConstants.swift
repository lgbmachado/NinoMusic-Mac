//
//  DbConstants.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 05/09/25.
//

import Foundation

struct DBConstants {
    
//    static let databasePath = (Bundle.main.bundlePath as NSString).deletingLastPathComponent + "/MusicDatabase.db"
    static let databasePath = "/Users/nino/MusicDatabase.db"

    struct TableAlbum {
        static let tableName = "Albuns"
        static let colRowId = "Albuns.RowId"
        static let colAlbum = "Albuns.Album"
        static let colYear = "Albuns.Year"
    }

    struct TableArtist {
        static let tableName = "Artists"
        static let colRowId = "Artists.RowId"
        static let colArtist = "Artists.Artist"
    }
    
    struct TableDiretory {
        static let tableName = "Directories"
        static let colRowId = "Directories.RowId"
        static let colDirName = "Directories.Name"
        static let colDirPath = "Directories.DirPath"
    }
    
    struct TableGenre {
        static let tableName = "Genres"
        static let colRowId = "Genres.RowId"
        static let colGenre = "Genres.Genre"
    }

    struct TableMusic {
        static let tableName = "Musics"
        static let colRowId = "Musics.RowId"
        static let colTitle = "Musics.Title"
        static let colIdArtist = "Musics.IdArtist"
        static let colIdAlbum = "Musics.IdAlbum"
        static let colTrack = "Musics.Track"
        static let colIdGenre = "Musics.IdGenre"
        static let colDuration = "Musics.Duration"
        static let colFilePath = "Musics.FilePath"
    }
}
