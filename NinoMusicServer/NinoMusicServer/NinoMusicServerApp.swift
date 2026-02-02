//
//  NinoMusicServerApp.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 24/02/25.
//

import SwiftUI
import SwiftData

@main
struct NinoMusicServerApp: App {
    
    var musicPlayerViewModel: MusicPlayerViewModel
    var libraryViewModel: LibraryViewModel
    var musicsViewModel: MusicsViewModel
    var artistsViewModel: ArtistsViewModel
    var albunsViewModel: AlbunsViewModel
    var serverViewModel: ServerViewModel
    
    let modelContainer: ModelContainer
    
    init() {
        // Configurar SwiftData ModelContainer
        let schema = Schema([
            Music.self,
            Album.self,
            AlbumMusic.self,
            Artist.self,
            ArtistAlbum.self,
            ArtistMusic.self,
            MusicDirectory.self
        ])
        let storeURL = URL.documentsDirectory.appending(path: "music.db")
        let configuration = ModelConfiguration(url: storeURL)
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Não foi possível criar o ModelContainer: \(error)")
        }
        
        self.musicPlayerViewModel = MusicPlayerViewModel()
        self.libraryViewModel = LibraryViewModel(modelContext: modelContainer.mainContext)
        self.musicsViewModel = MusicsViewModel(musicPlayerViewModel: musicPlayerViewModel, modelContext: modelContainer.mainContext)
        self.artistsViewModel = ArtistsViewModel(musicPlayerViewModel: musicPlayerViewModel, modelContext: modelContainer.mainContext)
        self.albunsViewModel = AlbunsViewModel(musicPlayerViewModel: musicPlayerViewModel, modelContext: modelContainer.mainContext)
        self.serverViewModel = ServerViewModel(modelContext: modelContainer.mainContext)
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
            .modelContainer(modelContainer)
        }
    }
}

