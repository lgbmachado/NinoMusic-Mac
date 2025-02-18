//
//  SelectionView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 07/08/24.
//

import SwiftUI

struct SelectionView: View {
    var menuSelection: MenuSelection
    @State var musics = Musics()
    @State var music = Music(artist: "",
                             album: "",
                             year: "",
                             track: 0,
                             musicTitle: "",
                             genre: "",
                             filePath: "")
    
    @State private var inspectorIsShown: Bool = false
    
    var body: some View {
        VStack {
            switch menuSelection {
            case .directories:
                DirectoriesView(musics: $musics)
            case .musics:
                MusicsView(music: $music, musics: $musics)
            case .artists:
                ArtistsView(musics: $musics)
            case .albuns:
                AlbunsView(musics: $musics)
            case .tags:
                TagEditorView(musics: $musics)
            case .server:
                ServerView(musics: $musics)
            }
        }
        .toolbar {
            if menuSelection == .musics || menuSelection == .artists || menuSelection == .albuns{
                ToolbarItem(placement: .navigation) {
                    MusicControlView(music: $music)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        inspectorIsShown.toggle()
                    } label: {
                        Label("Exibe Inspector", systemImage: "sidebar.right")
                    }
                }
            }
        }
        .inspector(isPresented: $inspectorIsShown) {
            Group {
                MusicDetailsView()
            }
            .frame(minWidth: 100, maxWidth: .infinity)
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
    SelectionView(menuSelection: .musics, musics: Musics())
}
