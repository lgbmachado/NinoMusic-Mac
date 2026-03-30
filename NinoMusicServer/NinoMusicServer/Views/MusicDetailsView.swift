//
//  MusicDetailsView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 24/01/25.
//

import SwiftUI
import ID3TagEditor

struct MusicDetailsView: View {
    @ObservedObject var tagEditorViewModel: TagEditorViewModel
    
    var body: some View {
        VStack {
            TabView {
                TagView(tagEditorViewModel: tagEditorViewModel)
                    .tabItem {
                        Image(systemName: "tag")
                        Text(LocalizedStringKey("text_tag"))
                    }
                FileView(tagEditorViewModel: tagEditorViewModel)
                    .tabItem {
                        Image(systemName: "folder")
                        Text(LocalizedStringKey("text_file"))
                    }
            }
        }
    }
}

struct TagView: View {
    @ObservedObject var tagEditorViewModel: TagEditorViewModel
    @State private var selectedGenre = "ROCK"
    let genres: [String] = ["ROCK", "PAGODE/FORRÓ", "INSTRUMENTAL/CLÁSSICO", "MPB", "SERTANEJO", "POP", "DANCE"]
    
    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.zeroSymbol = ""
        return formatter
    }()
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text(LocalizedStringKey("text_music"))
                    .font(.caption2)
                    .padding(.bottom, -7)
                TextField(
                    LocalizedStringKey("text_music"),
                    text: Binding(
                        get: { tagEditorViewModel.musicSelected.musicTitle },
                        set: {_,_ in }
                    ),
                    prompt: Text(LocalizedStringKey("text_music"))
                )
                
                Text(LocalizedStringKey("text_artist"))
                    .font(.caption2)
                    .padding(.bottom, -7)
                TextField(
                    LocalizedStringKey("text_artist"),
                    text: Binding(
                        get: { tagEditorViewModel.musicSelected.artist },
                        set: {_,_ in }
                    ),
                    prompt: Text(LocalizedStringKey("text_artist"))
                )
                
                Text(LocalizedStringKey("text_album"))
                    .font(.caption2)
                    .padding(.bottom, -7)
                TextField(
                    LocalizedStringKey("text_album"),
                    text: Binding(
                        get: { tagEditorViewModel.musicSelected.album },
                        set: {_,_ in }
                    ),
                    prompt: Text(LocalizedStringKey("text_album"))
                )
                
                Text(LocalizedStringKey("text_year"))
                    .font(.caption2)
                    .padding(.bottom, -7)
                TextField(LocalizedStringKey("text_year"),
                          text: Binding(
                            get: { tagEditorViewModel.musicSelected.year },
                            set: {_,_ in }
                          ),
                          prompt: Text(LocalizedStringKey("text_year"))
                )
                
                Text(LocalizedStringKey("text_track"))
                    .font(.caption2)
                    .padding(.bottom, -7)
                TextField(
                    LocalizedStringKey("text_track"),
                    text: Binding(
                        get: { String(tagEditorViewModel.musicSelected.track) },
                        set: {_,_ in }
                    ),
                    prompt: Text(LocalizedStringKey("text_track"))
                )
                
                Text(LocalizedStringKey("text_genre"))
                    .font(.caption2)
                    .padding(.bottom, -7)
                ComboBox(
                    text: Binding(
                        get: { tagEditorViewModel.musicSelected.genre },
                        set: {_,_ in }
                    ),
                    items: tagEditorViewModel.genresAvaiables,
                    placeholder: String(localized: "text_genre")
                )
                .frame(width: 200)
                Spacer()
                
                Text(LocalizedStringKey("text_album_cover"))
                    .font(.caption2)
                    .padding(.bottom, -7)
                Image(nsImage: Id3TagUtils.getImageCover(path: self.tagEditorViewModel.musicSelected.filePath) ?? NSImage())
                    .resizable()
                    .frame(width: .infinity, height: .infinity, alignment: .bottom)
                    .scaledToFit()
                    .aspectRatio(contentMode: .fit)
                    .border(.black)
                
                Spacer()
            }
        }
    }
}

struct FileView: View {
    @ObservedObject var tagEditorViewModel: TagEditorViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(LocalizedStringKey("text_file"))
                .font(.caption2)
                .padding(.bottom, -7)
            TextField(LocalizedStringKey("text_file_name"), text: $tagEditorViewModel.fileSelected)
            Spacer()
        }
    }
}
