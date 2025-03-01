//
//  ContentView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 24/02/25.
//

import SwiftUI

struct ContentView: View {

    @State var musics = Musics()
    @State private var selection: ItemMenu = .musics

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
        } detail: {
            switch selection {
            case .libray:
                LibraryView(musics: $musics)
                    .navigationTitle("")
            case .musics:
                MusicsView(musics: $musics)
                    .navigationTitle("")
            case .tags:
                TagEditorView(musics: $musics)
                    .navigationTitle("")
            case .server:
                ServerView()
                    .navigationTitle("")
            }
        }
        .task {
            let musicDb = Database()
            let musicsTemp = Musics()
            musicsTemp.musics = musicDb.getMusics()
            musics = musicsTemp
        }
    }
}

#Preview {
    ContentView()
}
