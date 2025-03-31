//
//  TagEditoView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 27/01/25.
//

import SwiftUI

struct TagEditorView: View {
    @ObservedObject var musicsViewModel: MusicsViewModel
    
    @State private var sortOrder = [KeyPathComparator(\Music.musicTitle)]
    @State private var searchTerm: String = ""
    @State var selection: Music.ID? = nil

    var tableData: [Music] {
        if searchTerm.isEmpty {
            return musicsViewModel.musics.sorted(using: sortOrder)
        } else {
            return musicsViewModel.musics
                .filter { $0.musicTitle.lowercased().contains(searchTerm.lowercased()) ||
                    $0.artist.lowercased().contains(searchTerm.lowercased()) ||
                    $0.album.lowercased().contains(searchTerm.lowercased()) ||
                    $0.genre.lowercased().contains(searchTerm.lowercased())}
                .sorted(using: sortOrder)
        }
    }
    
    @State private var inspectorIsShown: Bool = false
    
    var body: some View {
        Table(tableData, selection: $selection, sortOrder: $sortOrder) {
            TableColumn(LocalizedStringKey("text_file_name")) { (music: Music) in
                Text(verbatim: "\(((music.filePath as NSString).lastPathComponent).replacingOccurrences(of: "%20", with: " "))")
            }
            TableColumn(LocalizedStringKey("text_title"), value: \.musicTitle)
            TableColumn(LocalizedStringKey("text_artist"), value: \.artist)
                .width(150)
            TableColumn(LocalizedStringKey("text_album"), value: \.album)
            TableColumn(LocalizedStringKey("text_track")) { music in
                Text("\(music.track)")
            }
            .width(40)
            TableColumn(LocalizedStringKey("text_year"), value: \.year)
                .width(50)
            TableColumn(LocalizedStringKey("text_genre"), value: \.genre)
                .width(100)
        }
        .padding()
        .onChange(of: selection) { oldSelected, newSelected in
            musicsViewModel.setIdSelection(selection: newSelected ?? UUID())
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
                MusicDetailsView(musicsViewModel: self.musicsViewModel)
            }
            .frame(minWidth: 100, maxWidth: .infinity)
        }
        .searchable(text: $searchTerm)
    }
}

#Preview {
    TagEditorView(musicsViewModel: MusicsViewModel())
}
