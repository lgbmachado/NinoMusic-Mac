//
//  ContentView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 24/02/25.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var musicPlayerViewModel: MusicPlayerViewModel
    
    @ObservedObject var libraryViewModel: LibraryViewModel
    @ObservedObject var musicsViewModel: MusicsViewModel
    @ObservedObject var artistsViewModel: ArtistsViewModel
    @ObservedObject var albunsViewModel: AlbunsViewModel
    @ObservedObject var serverViewModel: ServerViewModel
    
    @State private var selection: ItemMenu = .musics

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
        } detail: {
            switch selection {
            case .libray:
                LibraryView(musicsViewModel: musicsViewModel, libraryViewModel: libraryViewModel)
                    .navigationTitle(String())
            case .musics:
                MusicsView(musicPlayerViewModel: musicPlayerViewModel, musicsViewModel: musicsViewModel)
                    .navigationTitle(String())
            case .artists:
                ArtistsView(artistsViewModel: artistsViewModel)
                    .navigationTitle(String())
            case .albuns:
                AlbunsView(albunsViewModel: albunsViewModel)
                    .navigationTitle(String())
            case .tags:
                TagEditorView(musicsViewModel: musicsViewModel)
                    .navigationTitle(String())
            case .server:
                ServerView(serverViewModel: serverViewModel)
                    .navigationTitle(String())
            }
        }
        .task {   
            musicsViewModel.musics = libraryViewModel.musics
        }
    }
}

#Preview {
    ContentView(musicPlayerViewModel: MusicPlayerViewModel(), libraryViewModel: LibraryViewModel(), musicsViewModel: MusicsViewModel(), artistsViewModel: ArtistsViewModel(), albunsViewModel: AlbunsViewModel(), serverViewModel: ServerViewModel())
}
