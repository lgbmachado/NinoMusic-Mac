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
    
    @State private var inspectorIsShown: Bool = false
    
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
        .onChange(of: selection) { oldSelected, newSelected in
            musics.idMusicSelected = newSelected ?? UUID()
        }
        .toolbar{
            ToolbarItem(placement: .primaryAction) {
                Button {
                    inspectorIsShown.toggle()
                } label: {
                    Label(LocalizedStringKey("text_show_details"), systemImage: "sidebar.right")
                }
            }
        }
        .inspector(isPresented: $inspectorIsShown) {
            Group {
                MusicDetailsView()
            }
            .frame(minWidth: 100, maxWidth: .infinity)
        }
    }
}

#Preview {
    TagEditorView(musics: .constant(Musics()))
}
