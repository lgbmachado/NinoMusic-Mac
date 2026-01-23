//
//  NinoMusicServerApp.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 24/02/25.
//

import SwiftUI

@main
struct NinoMusicServerApp: App {
    
    var musicPlayerViewModel: MusicPlayerViewModel
    var libraryViewModel: LibraryViewModel
    var musicsViewModel: MusicsViewModel
    var artistsViewModel: ArtistsViewModel
    var albunsViewModel: AlbunsViewModel
    var serverViewModel: ServerViewModel
    
    init() {
        self.musicPlayerViewModel = MusicPlayerViewModel()
        self.libraryViewModel = LibraryViewModel()
        self.musicsViewModel = MusicsViewModel(musicPlayerViewModel: musicPlayerViewModel)
        self.artistsViewModel = ArtistsViewModel(musicPlayerViewModel: musicPlayerViewModel)
        self.albunsViewModel = AlbunsViewModel(musicPlayerViewModel: musicPlayerViewModel)
        self.serverViewModel = ServerViewModel()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(musicPlayerViewModel: musicPlayerViewModel,
                        libraryViewModel: libraryViewModel,
                        musicsViewModel: musicsViewModel,
                        artistsViewModel: artistsViewModel,
                        albunsViewModel: albunsViewModel,
                        serverViewModel: serverViewModel)
            .environmentObject(musicPlayerViewModel)
        }
    }
}
