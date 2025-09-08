//
//  NinoMusicServerApp.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 24/02/25.
//

import SwiftUI

@main
struct NinoMusicServerApp: App {
    @StateObject var playerVM = MusicPlayerViewModel()
    var body: some Scene {
        WindowGroup {
            ContentView(musicPlayerViewModel: MusicPlayerViewModel(),
                        libraryViewModel: LibraryViewModel(),
                        musicsViewModel: MusicsViewModel(),
                        artistsViewModel: ArtistsViewModel(),
                        albunsViewModel: AlbunsViewModel(),
                        serverViewModel: ServerViewModel())
            .environmentObject(playerVM)
        }
    }
}
