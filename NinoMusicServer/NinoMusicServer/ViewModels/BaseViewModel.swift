//
//  BaseViewModel.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Baptista Machado on 24/01/26.
//

import Foundation
import SQLite3

class BaseViewModel: NSObject, ObservableObject {
    let musicPlayerViewModel: MusicPlayerViewModel
    let helper = DbHelper(path: DbConstants.databasePath)
    @Published var idMusicSelected: UUID? = nil
    @Published var fileSelected: String = String()
    @Published var musicSelected: Music = Music.emptyMusic
    @Published var isLoading: Bool = false
    
    init(musicPlayerViewModel: MusicPlayerViewModel) {
        self.musicPlayerViewModel = musicPlayerViewModel
        super.init()
        NotificationCenter.default.addObserver(forName: Notification.Name("nextTapped"),
                                               object: nil,
                                               queue: .main) { [weak self] notification in
            guard let self = self else { return }
            self.onNavigateMusics(kind: .next, originNotification: notification.userInfo?["origin"] as? MusicContentViewType)
        }
        NotificationCenter.default.addObserver(forName: Notification.Name("previousTapped"),
                                               object: nil,
                                               queue: .main) { [weak self] notification in
            guard let self = self else { return }
            self.onNavigateMusics(kind: .previus, originNotification: notification.userInfo?["origin"] as? MusicContentViewType)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func onNavigateMusics(kind: NavigationKind, originNotification: MusicContentViewType?) {
    }
    
    func saveFavorite(idServer: Int, isFavorite: Bool) {
        let sql = """
            UPDATE \(DbConstants.TableMusic.tableName)
            SET \(DbConstants.TableMusic.colIsFavorite) = \(isFavorite ? 1 : 0)
            WHERE \(DbConstants.TableMusic.colMusicId) = \(idServer)
            """
        guard self.helper?.executeQuery(query: sql) == true else { return }
        
        if self.musicPlayerViewModel.currentMusic?.idServer == idServer {
            self.musicPlayerViewModel.currentMusic?.isFavorite = isFavorite
        }
        NotificationCenter.default.post(name: Notification.Name("musicFavoriteChanged"),
                                        object: nil,
                                        userInfo: ["idServer": idServer, "isFavorite": isFavorite])
    }
    
    func OpenDb() -> OpaquePointer? {
        var database: OpaquePointer?
        if sqlite3_open_v2(DbConstants.databasePath, &database, SQLITE_OPEN_CREATE|SQLITE_OPEN_READWRITE|SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK {
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
 
}
