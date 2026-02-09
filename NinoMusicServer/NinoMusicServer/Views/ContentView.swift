//
//  ContentView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 24/02/25.
//

import SwiftUI

enum MusicContentViewType: Identifiable, CaseIterable, Hashable {
    case musics
    case artists
    case albuns

    var id: String {
        switch self {
        case .musics:
            "musics"
        case .artists:
            "artists"
        case .albuns:
            "albuns"
        }
    }
}

struct ContentView: View {
    @ObservedObject var musicPlayerViewModel: MusicPlayerViewModel
    
    @ObservedObject var libraryViewModel: LibraryViewModel
    @ObservedObject var musicsViewModel: MusicsViewModel
    @ObservedObject var tagEditorViewModel: TagEditorViewModel
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
                ArtistsView(musicPlayerViewModel: musicPlayerViewModel, artistsViewModel: artistsViewModel)
                    .navigationTitle(String())
            case .albuns:
                AlbunsView(musicPlayerViewModel: musicPlayerViewModel, albunsViewModel: albunsViewModel)
                    .navigationTitle(String())
            case .tags:
                TagEditorView(tagEditorViewModel: tagEditorViewModel)
                    .navigationTitle(String())
            case .server:
                ServerView(serverViewModel: serverViewModel)
                    .navigationTitle(String())
            }
        }
        .task {   
            musicsViewModel.reloadMusics()
            artistsViewModel.reloadArtists()
            albunsViewModel.reloadAlbuns()
        }
    }
}
