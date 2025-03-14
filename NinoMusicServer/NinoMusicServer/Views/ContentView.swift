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
    @ObservedObject var serverViewModel: ServerViewModel
    
    @State private var selection: ItemMenu = .musics

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
        } detail: {
            switch selection {
            case .libray:
                LibraryView(musicsViewModel: musicsViewModel, libraryViewModel: libraryViewModel)
                    .navigationTitle("")
            case .musics:
                MusicsView(musicsViewModel: musicsViewModel)
                    .navigationTitle("")
            case .tags:
                TagEditorView(musicsViewModel: musicsViewModel)
                    .navigationTitle("")
            case .server:
                ServerView(serverViewModel: serverViewModel)
                    .navigationTitle("")
            }
        }
        .task {   
            libraryViewModel.loadMusics()
            musicsViewModel.musics = libraryViewModel.musics
        }
    }
}

#Preview {
    ContentView(libraryViewModel: LibraryViewModel(), musicsViewModel: MusicsViewModel(), serverViewModel: ServerViewModel())
}
