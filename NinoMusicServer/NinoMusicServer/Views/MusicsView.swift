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
    @Binding var idMusicSelected: Music.ID

    @State private var sortOrder = [KeyPathComparator(\Music.musicTitle)]
    @State var selection: Music.ID? = nil
    
    var tableData: [Music] {
        return musics.musics.sorted(using: sortOrder)
    }
    
    var body: some View {
        Table(tableData, selection: $selection, sortOrder: $sortOrder) {
            TableColumn(LocalizedStringKey("text_title"), value: \.musicTitle)
            TableColumn(LocalizedStringKey("text_artist"), value: \.artist)
            TableColumn(LocalizedStringKey("text_album"), value: \.album)
            TableColumn(LocalizedStringKey("text_track")) { music in
                Text("\(music.track)")
            }
            TableColumn(LocalizedStringKey("text_year"), value: \.year)
            TableColumn(LocalizedStringKey("text_genre"), value: \.genre)
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

struct MusicRowView: View {
    
    @State var music: Music
    
    var body: some View {
        GridRow {
            Text(music.musicTitle)
                .bold()
            Text(music.artist)
            Text(music.album)
            Text(String(format: "%d", music.track))
                .gridColumnAlignment(.trailing)
            Text(music.year)
            Text(music.genre)
        }
    }
}

#Preview {
    MusicsView(music: .constant(Music.example), musics: .constant(Musics()), idMusicSelected: .constant(UUID()))
}
