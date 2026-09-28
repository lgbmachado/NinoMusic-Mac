//
//  ArtistsViewModel.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 03/09/25.
//

import Foundation
import SQLite3

struct Node: Identifiable {
    var id: UUID?
    let name: String
    var children: [Node]?
    var musics: [ArtistMusic]?
}

class ArtistsViewModel: BaseViewModel {
    @Published var artists: [Artist] = []
    @Published var idAlbumSelected: UUID? = nil
    @Published var idArtistSelected: Artist.ID? = nil
    @Published var albumSelected: ArtistAlbum = ArtistAlbum.emptyAlbum
    @Published var artistSelected: Artist = Artist.emptyArtist
    
    override init(musicPlayerViewModel: MusicPlayerViewModel) {
        super.init(musicPlayerViewModel: musicPlayerViewModel)
        NotificationCenter.default.addObserver(forName: Notification.Name("musicExecuted"),
                                               object: nil,
                                               queue: .main) { [weak self] notification in
            guard let self = self,
                  let idServer = notification.userInfo?["idServer"] as? Int,
                  let lastExecution = notification.userInfo?["lastExecution"] as? Date,
                  let countExecution = notification.userInfo?["countExecution"] as? Int else { return }
            self.updateExecution(idServer: idServer, lastExecution: lastExecution, countExecution: countExecution)
        }
    }
    
    private func updateExecution(idServer: Int, lastExecution: Date, countExecution: Int) {
        for artistIndex in self.artists.indices {
            for albumIndex in self.artists[artistIndex].albuns.indices {
                if let musicIndex = self.artists[artistIndex].albuns[albumIndex].musics.firstIndex(where: { $0.idServer == idServer }) {
                    self.artists[artistIndex].albuns[albumIndex].musics[musicIndex].lastExecution = lastExecution
                    self.artists[artistIndex].albuns[albumIndex].musics[musicIndex].countExecution = countExecution
                    if self.albumSelected.id == self.artists[artistIndex].albuns[albumIndex].id {
                        self.albumSelected = self.artists[artistIndex].albuns[albumIndex]
                    }
                }
            }
        }
        if self.musicSelected.idServer == idServer {
            self.musicSelected.lastExecution = lastExecution
            self.musicSelected.countExecution = countExecution
        }
    }
    
    override func onNavigateMusics(kind: NavigationKind, originNotification: MusicContentViewType?) {
        if originNotification == .artists {
            let searchCount = kind == .next ? musicSelected.seq + 1 : musicSelected.seq - 1
            if let selected = self.albumSelected.musics.first(where: {$0.seq == searchCount}) {
                self.idMusicSelected = selected.id
                self.setIdSelection(selection: self.idMusicSelected ?? UUID())
                musicPlayerViewModel.setMusicSelected(music: self.musicSelected)
                musicPlayerViewModel.originCurrentMusic = .albuns
            }
        }
    }
    
    func getNodes() -> [Node] {
        var nodes = [Node]()
        for artist in self.artists {
            var node = Node(id: artist.id, name: artist.artist)
            node.children = [Node]()
            node.musics = nil
            for album in artist.albuns {
                var subNode = Node(id: album.id, name: album.album)
                subNode.children = nil
                subNode.musics = album.musics
                node.children?.append(subNode)
            }
            nodes.append(node)
        }
        return nodes
    }

    // Artists are pre-sorted alphabetically, so grouping preserves order
    func getGroupedNodes() -> [(letter: String, nodes: [Node])] {
        var groups = [(letter: String, nodes: [Node])]()
        for node in getNodes() {
            let letter = String(node.name.first ?? " ").uppercased()
            if groups.last?.letter == letter {
                groups[groups.count - 1].nodes.append(node)
            } else {
                groups.append((letter: letter, nodes: [node]))
            }
        }
        return groups
    }
    
    func setIdSelection(selection: Music.ID) {
        for artist in self.artists {
            for album in artist.albuns {
                if let item = album.musics.first(where: { $0.id == selection }) {
                    self.artistSelected = artist
                    self.albumSelected = album
                    
                    self.musicSelected.id = item.id
                    self.musicSelected.seq = item.seq
                    self.musicSelected.idServer = item.idServer
                    self.musicSelected.artist = artist.artist
                    self.musicSelected.album = album.album
                    self.musicSelected.year = album.year
                    self.musicSelected.track = item.track
                    self.musicSelected.musicTitle = item.musicTitle
                    self.musicSelected.genre = artist.genre
                    self.musicSelected.duration = item.duration
                    self.musicSelected.filePath = item.filePath
                    self.musicSelected.hasLyric = item.hasLyric
                    self.musicSelected.lastUpdate = item.lastUpdate
                    self.musicSelected.lastExecution = item.lastExecution
                    self.musicSelected.countExecution = item.countExecution
                    return
                }
            }
        }
    }
    
    func reloadArtists() async {
        let sqlArtist = """
    SELECT DISTINCT
       \(DbConstants.TableMusic.colIdArtist),
       \(DbConstants.TableArtist.colArtist),
       \(DbConstants.TableGenre.colGenre)
    FROM
       \(DbConstants.TableMusic.tableName)
       INNER JOIN \(DbConstants.TableArtist.tableName) ON \(DbConstants.TableArtist.tableName).\(DbConstants.TableArtist.colArtistId) = \(DbConstants.TableMusic.colIdArtist)
       INNER JOIN \(DbConstants.TableGenre.tableName) ON \(DbConstants.TableGenre.tableName).\(DbConstants.TableGenre.colGenreId) = \(DbConstants.TableMusic.colIdGenre)
    ORDER BY
       \(DbConstants.TableArtist.colArtist),
       \(DbConstants.TableMusic.colTrack)
    """
        await MainActor.run {
            self.isLoading = true
        }

        let artistList = await withCheckedContinuation { (continuation: CheckedContinuation<[Artist], Never>) in
            DispatchQueue.global(qos: .userInitiated).async {
                var artistList = [Artist]()
                var artistAlbumList = [ArtistAlbum]()
                var artistMusicList = [ArtistMusic]()
                var seqArtist = 0
                var seqAlbum = 0
                var seqMusic = 0
                do {
                    if let rowsArtists = try self.helper?.sql(query: sqlArtist) {
                        for rowArtist in rowsArtists {
                            if let idArtist = rowArtist[DbConstants.TableMusic.colIdArtist] as? Int,
                               let artist = rowArtist[DbConstants.TableArtist.colArtist] as? String,
                               let genre = rowArtist[DbConstants.TableGenre.colGenre] as? String
                            {
                                seqArtist += 1
                                let sqlAlbuns = """
                                       SELECT DISTINCT
                                          \(DbConstants.TableAlbum.tableName).\(DbConstants.TableAlbum.colAlbumId),
                                          \(DbConstants.TableAlbum.colAlbum),
                                          \(DbConstants.TableAlbum.colYear)
                                       FROM
                                          \(DbConstants.TableMusic.tableName)
                                          INNER JOIN \(DbConstants.TableArtist.tableName) ON \(DbConstants.TableArtist.tableName).\(DbConstants.TableArtist.colArtistId) = \(DbConstants.TableMusic.colIdArtist)
                                          INNER JOIN \(DbConstants.TableAlbum.tableName) ON \(DbConstants.TableAlbum.tableName).\(DbConstants.TableAlbum.colAlbumId) = \(DbConstants.TableMusic.colIdAlbum)
                                       WHERE
                                          \(DbConstants.TableMusic.colIdArtist) = \(idArtist)
                                       ORDER BY
                                          \(DbConstants.TableAlbum.colYear),
                                          \(DbConstants.TableAlbum.colAlbum)
                                       
                                       """
                                seqAlbum = 0
                                do {
                                    if let rowsAlbuns = try self.helper?.sql(query: sqlAlbuns) {
                                        for rowAlbum in rowsAlbuns {
                                            if let idAlbum = rowAlbum[DbConstants.TableAlbum.colAlbumId] as? Int,
                                               let album = rowAlbum[DbConstants.TableAlbum.colAlbum] as? String,
                                               let year = rowAlbum[DbConstants.TableAlbum.colYear] as? Int
                                            {
                                                let sqlMusics = """
                                                         SELECT
                                                            \(DbConstants.TableMusic.colMusicId),
                                                            \(DbConstants.TableMusic.colTrack),
                                                            \(DbConstants.TableMusic.colTitle),
                                                            \(DbConstants.TableMusic.colDuration),
                                                            \(DbConstants.TableMusic.colFilePath),
                                                            \(DbConstants.TableMusic.colHasLyrics),
                                                            \(DbConstants.TableMusic.colLastUpdate),
                                                            \(DbConstants.TableMusic.colLastExecution),
                                                            \(DbConstants.TableMusic.colCountExecution)
                                                         FROM
                                                            \(DbConstants.TableMusic.tableName)
                                                         WHERE
                                                            \(DbConstants.TableMusic.colIdAlbum) = \(idAlbum) AND 
                                                            \(DbConstants.TableMusic.colIdArtist) = \(idArtist) 
                                                         ORDER BY
                                                            \(DbConstants.TableMusic.colTrack),
                                                            \(DbConstants.TableMusic.colTitle)
                                                         """
                                                do {
                                                    if let rowsMusicsAlbum = try self.helper?.sql(query: sqlMusics) {
                                                        seqMusic = 0
                                                        for rowMusicAlbum in rowsMusicsAlbum {
                                                            if let idServer = rowMusicAlbum[DbConstants.TableMusic.colMusicId] as? Int,
                                                               let track = rowMusicAlbum[DbConstants.TableMusic.colTrack] as? Int,
                                                               let musicTitle = rowMusicAlbum[DbConstants.TableMusic.colTitle] as? String,
                                                               let duration = rowMusicAlbum[DbConstants.TableMusic.colDuration] as? Int,
                                                               let filePath = rowMusicAlbum[DbConstants.TableMusic.colFilePath] as? String,
                                                               let hasLyric = rowMusicAlbum[DbConstants.TableMusic.colHasLyrics] as? Int,
                                                               let lastUpdate = rowMusicAlbum[DbConstants.TableMusic.colLastUpdate] as? Int,
                                                               let lastExecution = rowMusicAlbum[DbConstants.TableMusic.colLastExecution] as? Int,
                                                               let countExecution = rowMusicAlbum[DbConstants.TableMusic.colCountExecution] as? Int
                                                            {
                                                                seqMusic += 1
                                                                artistMusicList.append(ArtistMusic(seq: seqMusic,
                                                                                                   idServer: idServer,
                                                                                                   track: track,
                                                                                                   musicTitle: musicTitle,
                                                                                                   duration: duration,
                                                                                                   filePath: filePath,
                                                                                                   hasLyric: hasLyric == 1,
                                                                                                   lastUpdate: Date(timeIntervalSince1970: TimeInterval(lastUpdate)),
                                                                                                   lastExecution: Date(timeIntervalSince1970: TimeInterval(lastExecution)),
                                                                                                   countExecution: countExecution))
                                                            }
                                                        }
                                                        seqAlbum += 1
                                                        artistAlbumList.append(ArtistAlbum(seq: seqAlbum,
                                                                                           album: album,
                                                                                           year: year,
                                                                                           musics: artistMusicList))
                                                        
                                                        artistMusicList.removeAll()
                                                    }
                                                } catch {
                                                    print(error)
                                                }
                                            }
                                        }
                                        artistList.append(Artist(seq: seqArtist,
                                                                 artist: artist,
                                                                 genre: genre,
                                                                 albuns: artistAlbumList))
                                        artistAlbumList.removeAll()
                                    }
                                } catch {
                                    print(error)
                                }
                            }
                        }
                    }
                } catch {
                    print(error)
                }

                continuation.resume(returning: artistList)
            }
        }

        await MainActor.run {
            self.artists = artistList
            self.isLoading = false
        }
    }
}
