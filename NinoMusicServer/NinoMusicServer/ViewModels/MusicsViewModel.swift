//
//  MusicsViewModel.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 12/03/25.
//

import SwiftUI
import SQLite3

class MusicsViewModel: BaseViewModel {
    @Published var musics: [Music] = []
    
    override func onNavigate(kind: NavigationKind, originNotification: MusicContentViewType?) {
        if originNotification == .musics {
            let searchCount = kind == .next ? musicSelected.seq + 1 : musicSelected.seq - 1
            if let selected = self.musics.first(where: {$0.seq == searchCount}) {
                self.idMusicSelected = selected.id
                self.musicSelected = selected
                musicPlayerViewModel.setMusicSelected(music: selected)
                musicPlayerViewModel.originCurrentMusic = .musics
            }
        }
    }
    
    func reloadMusics() {
        let sql = """
            SELECT
               \(DBConstants.TableMusic.tableName).\(DBConstants.TableMusic.colRowId),
               \(DBConstants.TableArtist.colArtist),
               \(DBConstants.TableMusic.colTitle),
               \(DBConstants.TableMusic.colTrack),
               \(DBConstants.TableAlbum.colAlbum),
               \(DBConstants.TableGenre.colGenre),
               \(DBConstants.TableMusic.colDuration),
               \(DBConstants.TableAlbum.colYear),
               \(DBConstants.TableMusic.colFilePath),
               \(DBConstants.TableMusic.colHasLyrics)
            FROM
               \(DBConstants.TableMusic.tableName)
               INNER JOIN \(DBConstants.TableArtist.tableName) ON \(DBConstants.TableArtist.tableName).\(DBConstants.TableArtist.colRowId) = \(DBConstants.TableMusic.colIdArtist)
               INNER JOIN \(DBConstants.TableAlbum.tableName) ON \(DBConstants.TableAlbum.tableName).\(DBConstants.TableAlbum.colRowId) = \(DBConstants.TableMusic.colIdAlbum)
               INNER JOIN \(DBConstants.TableGenre.tableName) ON \(DBConstants.TableGenre.tableName).\(DBConstants.TableGenre.colRowId) = \(DBConstants.TableMusic.colIdGenre)
            ORDER BY
               \(DBConstants.TableMusic.colTitle),
               \(DBConstants.TableArtist.colArtist)
            """
        var musicList = [Music]()
        var seq = 0
        
        do {
            if let rows = try self.helper?.executeQuery(query: sql) {
                for row in rows {
                    seq += 1
                    if
                        let idServer = row[DBConstants.TableMusic.colRowId] as? Int,
                        let artist = row[DBConstants.TableArtist.colArtist] as? String,
                        let album = row[DBConstants.TableAlbum.colAlbum] as? String,
                        let year = row[DBConstants.TableAlbum.colYear] as? String,
                        let track = row[DBConstants.TableMusic.colTrack] as? Int,
                        let musicTitle = row[DBConstants.TableMusic.colTitle] as? String,
                        let genre = row[DBConstants.TableGenre.colGenre] as? String,
                        let duration = row[DBConstants.TableMusic.colRowId] as? Int,
                        let filePath = row[DBConstants.TableMusic.colFilePath] as? String,
                        let hasLyric = row[DBConstants.TableMusic.colHasLyrics] as? Int
                    {
                        musicList.append(Music(seq: seq,
                                               idServer: idServer,
                                               artist: artist,
                                               album: album,
                                               year: year,
                                               track: track,
                                               musicTitle: musicTitle,
                                               genre: genre,
                                               duration: duration,
                                               filePath: filePath,
                                               hasLyric: hasLyric == 1))
                    }
                }
            }
        } catch {
            print(error)
        }
        self.musics = musicList
    }
    
    func setIdSelection(selection: Music.ID) {
        self.idMusicSelected = selection
        if let item = self.musics.first(where: { $0.id == self.idMusicSelected }) {
            self.idMusicSelected = item.id
            self.musicSelected = item
            self.fileSelected = String((item.filePath as NSString).lastPathComponent).removingPercentEncoding?.replacingOccurrences(of: "file://", with: "") ?? ""
        } else {
            self.musicSelected = Music.emptyMusic
        }
    }
    
}
