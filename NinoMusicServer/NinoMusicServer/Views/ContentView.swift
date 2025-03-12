//
//  ContentView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 24/02/25.
//

import SwiftUI

struct ContentView: View {

    @ObservedObject var musicsViewModel: MusicsViewModel
    @State private var selection: ItemMenu = .musics

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
        } detail: {
            switch selection {
            case .libray:
                LibraryView(musicsViewModel: musicsViewModel)
                    .navigationTitle("")
            case .musics:
                MusicsView(musicsViewModel: musicsViewModel)
                    .navigationTitle("")
            case .tags:
                TagEditorView(musicsViewModel: musicsViewModel)
                    .navigationTitle("")
            case .server:
                ServerView()
                    .navigationTitle("")
            }
        }
        .task {   
            musicsViewModel.loadMusics()
        }
    }
}

#Preview {
    ContentView(musicsViewModel: MusicsViewModel())
}
