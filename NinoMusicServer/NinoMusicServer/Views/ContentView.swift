//
//  ContentView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 24/02/25.
//

import SwiftUI

struct ContentView: View {

    @ObservedObject var libraryViewModel: LibraryViewModel
    @ObservedObject var musicsViewModel: MusicsViewModel
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
                MusicsView(musicsViewModel: musicsViewModel)
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
    ContentView(libraryViewModel: LibraryViewModel(), musicsViewModel: MusicsViewModel(), albunsViewModel: AlbunsViewModel(), serverViewModel: ServerViewModel())
}
