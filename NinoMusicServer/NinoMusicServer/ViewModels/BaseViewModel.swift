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
    @Published var idMusicSelected: Music.ID? = nil
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
