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
                Text(tagEditorViewModel.selectedCountText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)

                Text(LocalizedStringKey("text_music"))
                    .font(.caption2)
                    .padding(.bottom, -7)
                TextField(
                    LocalizedStringKey("text_music"),
                    text: Binding(
                        get: { tagEditorViewModel.musicSelectedCommonFields.musicTitle },
                        set: { tagEditorViewModel.updateMusicTitle($0) }
                    ),
                    prompt: Text(tagEditorViewModel.hasCommonMusicTitle ? "" : "—")
                )
                
                Text(LocalizedStringKey("text_artist"))
                    .font(.caption2)
                    .padding(.bottom, -7)
                TextField(
                    LocalizedStringKey("text_artist"),
                    text: Binding(
                        get: { tagEditorViewModel.musicSelectedCommonFields.artist },
                        set: { tagEditorViewModel.updateArtist($0) }
                    ),
                    prompt: Text(tagEditorViewModel.hasCommonArtist ? "" : "—")
                )
                
                Text(LocalizedStringKey("text_album"))
                    .font(.caption2)
                    .padding(.bottom, -7)
                TextField(
                    LocalizedStringKey("text_album"),
                    text: Binding(
                        get: { tagEditorViewModel.musicSelectedCommonFields.album },
                        set: { tagEditorViewModel.updateAlbum($0) }
                    ),
                    prompt: Text(tagEditorViewModel.hasCommonAlbum ? "" : "—")
                )
                
                Text(LocalizedStringKey("text_year"))
                    .font(.caption2)
                    .padding(.bottom, -7)
                TextField(LocalizedStringKey("text_year"),
                          text: Binding(
                            get: { tagEditorViewModel.musicSelectedCommonFields.year },
                            set: { tagEditorViewModel.updateYear($0) }
                                                    ),
                                                    prompt: Text(tagEditorViewModel.hasCommonYear ? "" : "—"))
                
                Text(LocalizedStringKey("text_track"))
                    .font(.caption2)
                    .padding(.bottom, -7)
                TextField(
                    LocalizedStringKey("text_track"),
                    text: Binding(
                        get: { tagEditorViewModel.trackFieldText },
                        set: { tagEditorViewModel.updateTrackFromField($0) }
                    ),
                    prompt: Text(tagEditorViewModel.hasCommonTrack ? "" : "—")
                )
                
                Text(LocalizedStringKey("text_genre"))
                    .font(.caption2)
                    .padding(.bottom, -7)
                ComboBox(
                    text: Binding(
                        get: { tagEditorViewModel.musicSelectedCommonFields.genre },
                        set: { tagEditorViewModel.updateGenre($0) }
                    ),
                    items: tagEditorViewModel.genresAvaiables,
                    placeholder: tagEditorViewModel.hasCommonGenre ? nil : "—"
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
