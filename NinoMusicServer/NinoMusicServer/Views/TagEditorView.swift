//
//  TagEditoView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 27/01/25.
//

import SwiftUI

struct TagEditorView: View {
    @Binding var musics: Musics
    
    @State private var sortOrder = [KeyPathComparator(\Music.musicTitle)]
    @State private var selection: Music.ID? = nil
    
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
                print("Item selecionado:\n  ID: \(item.id)\n  Música: \(item.musicTitle)\n  Artista: \(item.artist)")
                
            }
        }
    }
}

#Preview {
    TagEditorView(musics: .constant(Musics()))
}
