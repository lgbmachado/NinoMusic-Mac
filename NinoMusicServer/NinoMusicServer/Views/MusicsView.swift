//
//  MusicsView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 05/08/24.
//

import SwiftUI


struct MusicsView: View {
    @Binding var music: Music
    @Binding var musics: Musics

    @State private var sortOrder = [KeyPathComparator(\Music.musicTitle)]
    @State var selection: Music.ID? = nil
    
    var tableData: [Music] {
        return musics.musics.sorted(using: sortOrder)
    }
    
    var body: some View {
        Table(tableData, selection: $selection, sortOrder: $sortOrder) {
            TableColumn("Título", value: \.musicTitle)
            TableColumn("Artista", value: \.artist)
            TableColumn("Álbum", value: \.album)
            TableColumn("Trilha") { music in
                Text("\(music.track)")
            }
            TableColumn("Ano", value: \.year)
            TableColumn("Gênero", value: \.genre)
        }
        .padding()
        .onChange(of: selection) { selected in
            musics.idMusicSelected = selected ?? UUID()
            if let item = musics.musicSelected {
                music = item
            }
        }
    }
}

#Preview {
    MusicsView(music: .constant(Music.example), musics: .constant(Musics()))
}
