//
//  BaseViewModel.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Baptista Machado on 24/01/26.
//

import Foundation
import SwiftData

class BaseViewModel: NSObject, ObservableObject {
    let musicPlayerViewModel: MusicPlayerViewModel
    let modelContext: ModelContext
    @Published var idMusicSelected: UUID? = nil
    @Published var fileSelected: String = String()
    @Published var musicSelected: Music = Music.emptyMusic
    
    init(musicPlayerViewModel: MusicPlayerViewModel, modelContext: ModelContext) {
        self.musicPlayerViewModel = musicPlayerViewModel
        self.modelContext = modelContext
        super.init()
        NotificationCenter.default.addObserver(forName: Notification.Name("nextTapped"),
                                               object: nil,
                                               queue: .main) { [weak self] notification in
            guard let self = self else { return }
            self.onNavigate(kind: .next, originNotification: notification.userInfo?["origin"] as? MusicContentViewType)
        }
        NotificationCenter.default.addObserver(forName: Notification.Name("previousTapped"),
                                               object: nil,
                                               queue: .main) { [weak self] notification in
            guard let self = self else { return }
            self.onNavigate(kind: .previus, originNotification: notification.userInfo?["origin"] as? MusicContentViewType)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func onNavigate(kind: NavigationKind, originNotification: MusicContentViewType?) {
    }
}

