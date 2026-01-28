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
                MusicsContentView(musicContentViewType: .musics, musicPlayerViewModel: musicPlayerViewModel, musicsViewModel: musicsViewModel, artistsViewModel: artistsViewModel, albunsViewModel: albunsViewModel)
                    .navigationTitle(String())
            case .artists:
                MusicsContentView(musicContentViewType: .artists, musicPlayerViewModel: musicPlayerViewModel, musicsViewModel: musicsViewModel, artistsViewModel: artistsViewModel, albunsViewModel: albunsViewModel)
                    .navigationTitle(String())
            case .albuns:
                MusicsContentView(musicContentViewType: .albuns, musicPlayerViewModel: musicPlayerViewModel, musicsViewModel: musicsViewModel, artistsViewModel: artistsViewModel, albunsViewModel: albunsViewModel)
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
            musicsViewModel.reloadMusics()
            artistsViewModel.reloadArtists()
            albunsViewModel.reloadAlbuns()
        }
    }
}
