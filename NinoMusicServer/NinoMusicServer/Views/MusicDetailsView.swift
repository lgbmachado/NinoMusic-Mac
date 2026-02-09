//
//  MusicDetailsView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 24/01/25.
//

import SwiftUI

struct MusicDetailsView: View {
    @ObservedObject var tagEditorViewModel: TagEditorViewModel
    
    var body: some View {
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

struct TagView: View {
    @ObservedObject var tagEditorViewModel: TagEditorViewModel
    
    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.zeroSymbol = ""
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(LocalizedStringKey("text_music"))
                .font(.caption2)
                .padding(.bottom, -7)
            TextField(
                LocalizedStringKey("text_music_name"),
                text: $tagEditorViewModel.musicSelected.musicTitle
            )
            
            Text(LocalizedStringKey("text_artist"))
                .font(.caption2)
                .padding(.bottom, -7)
            TextField(
                LocalizedStringKey("text_artist_name"),
                text: $tagEditorViewModel.musicSelected.artist
            )
            
            Text(LocalizedStringKey("text_album"))
                .font(.caption2)
                .padding(.bottom, -7)
            TextField(
                LocalizedStringKey("text_album_name"),
                text: $tagEditorViewModel.musicSelected.album
            )
            
            Text(LocalizedStringKey("text_year"))
                .font(.caption2)
                .padding(.bottom, -7)
            TextField(LocalizedStringKey("text_year"),
                      text: $tagEditorViewModel.musicSelected.year)
            .onChange(of: tagEditorViewModel.musicSelected.year) { newValue in
                
            }
            
            Text(LocalizedStringKey("text_track"))
                .font(.caption2)
                .padding(.bottom, -7)
            TextField(
                LocalizedStringKey("text_track_number"),
                value: $tagEditorViewModel.musicSelected.track, formatter: formatter
            )
            
            Text(LocalizedStringKey("text_genre"))
                .font(.caption2)
                .padding(.bottom, -7)
            TextField(
                LocalizedStringKey("text_music_genre"),
                text: $tagEditorViewModel.musicSelected.genre
            )
            
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
