//
//  BaseViewModel.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Baptista Machado on 23/01/26.
//

import Foundation
import SQLite3

class BaseViewModel: NSObject, ObservableObject {
    let musicPlayerViewModel: MusicPlayerViewModel
    @Published var artists: [Artist] = []
    @Published var albuns: [Album] = []
    @Published var musics: [Music] = []
    @Published var idMusicSelected: Music.ID? = nil
    @Published var idAlbumSelected: Album.ID? = nil
    @Published var albumSelected: Album = Album.emptyAlbum
    @Published var fileSelected: String = String()
    @Published var musicSelected: Music = Music.emptyMusic
    @Published var artistSelected: Artist = Artist.emptyArtist
    
    init(musicPlayerViewModel: MusicPlayerViewModel) {
        self.musicPlayerViewModel = musicPlayerViewModel
        super.init()
        NotificationCenter.default.addObserver(forName: Notification.Name("nextTapped"),
                                               object: nil,
                                               queue: .main) { [weak self] notification in
            guard let self = self else { return }
            self.navigateSongs(kind: .next, originNotification: notification.userInfo?["origin"] as? MusicContentViewType)
        }
        NotificationCenter.default.addObserver(forName: Notification.Name("previousTapped"),
                                               object: nil,
                                               queue: .main) { [weak self] notification in
            guard let self = self else { return }
            self.navigateSongs(kind: .previus, originNotification: notification.userInfo?["origin"] as? MusicContentViewType)
        }
    }
    
    private func navigateSongs(kind: NavigationKind, originNotification: MusicContentViewType?) {
        if originNotification == .musics {
            var searchCount: Int?
            switch originNotification {
            case .albuns:
                searchCount = kind == .next ? musicSelected.seq + 1 : musicSelected.seq - 1
                if let selected = self.albumSelected.musics.first(where: {$0.seq == searchCount}) {
                    self.idMusicSelected = selected.id
                    self.setIdSelection(originNotification: originNotification, selection: self.idMusicSelected ?? UUID())
                    musicPlayerViewModel.setMusicSelected(music: self.musicSelected)
                    musicPlayerViewModel.originCurrentMusic = .albuns
                }
            case .artists:
                searchCount = kind == .next ? musicSelected.seq + 1 : musicSelected.seq - 1
            case .musics:
                searchCount = kind == .next ? musicSelected.seq + 1 : musicSelected.seq - 1
                if let selected = self.musics.first(where: {$0.seq == searchCount}) {
                    self.idMusicSelected = selected.id
                    self.musicSelected = selected
                    musicPlayerViewModel.setMusicSelected(music: selected)
                    musicPlayerViewModel.originCurrentMusic = .musics
                }
            case .none:
                break
            }
        }
    }
    
    func OpenDb() -> OpaquePointer? {
        var database: OpaquePointer?
        if sqlite3_open_v2(DBConstants.databasePath, &database, SQLITE_OPEN_CREATE|SQLITE_OPEN_READWRITE|SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK {
            return database
        }
        print("Erro ao abrir banco de dados!")
        return nil
    }
    
    func CloseDb(database: OpaquePointer?) {
        if let database = database {
            if sqlite3_close(database) != SQLITE_OK {
                print("Erro ao fechar banco de dados!")
            }
        }
    }
    
    func setIdSelection(originNotification: MusicContentViewType?, selection: Music.ID) {
        switch originNotification {
        case .albuns:
            for album in albuns {
                if let item = album.musics.first(where: { $0.id == selection }) {
                    self.musicSelected.id = item.id
                    self.musicSelected.seq = item.seq
                    self.musicSelected.idServer = item.idServer
                    self.musicSelected.artist = album.artist
                    self.musicSelected.album = album.album
                    self.musicSelected.year = album.year
                    self.musicSelected.track = item.track
                    self.musicSelected.musicTitle = item.musicTitle
                    self.musicSelected.genre = album.genre
                    self.musicSelected.duration = item.duration
                    self.musicSelected.filePath = item.filePath
                }
            }
        case .artists:
            for artist in self.artists {
                for album in artist.albuns {
                    if let item = album.musics.first(where: { $0.id == selection }) {
                        self.artistSelected = artist
                        //                        self.albumSelected = album
                        
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
                        return
                    }
                }
            }
        case .musics:
            self.idMusicSelected = selection
            if let item = self.musics.first(where: { $0.id == self.idMusicSelected }) {
                self.idMusicSelected = item.id
                self.musicSelected = item
                self.fileSelected = String((item.filePath as NSString).lastPathComponent).removingPercentEncoding?.replacingOccurrences(of: "file://", with: "") ?? ""
            } else {
                self.musicSelected = Music.emptyMusic
            }
        case .none:
            break
        }
        
    }
}
