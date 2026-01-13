//
//  AlbunsView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 01/04/25.
//

import SwiftUI

struct AlbunsView: View {
    @EnvironmentObject var musicPlayerViewModel: MusicPlayerViewModel
    @ObservedObject var albunsViewModel: AlbunsViewModel
    @State var selection: Music.ID? = nil
    
    var tableData: [AlbumMusic] {
        return albunsViewModel.albumSelected.musics
    }
    
    var body: some View {
        VStack {
            Image(nsImage: Id3TagUtils.getImageCover(path: albunsViewModel.filePathCover) ?? NSImage())
                .resizable()
                .frame(width: 300, height: 300, alignment: .bottom)
                .scaledToFit()
                .aspectRatio(contentMode: .fit)
                .border(.black)
                .padding()
            
            Text(verbatim: albunsViewModel.albumSelected.album)
                .font(.title)
            Text(verbatim: albunsViewModel.albumSelected.artist)
                .font(.title3)
            Text(verbatim: albunsViewModel.albumSelected.year)
                .font(.caption2)
            Text(verbatim: albunsViewModel.albumSelected.genre)
                .font(.caption2)
            HStack {
                Button(String(), systemImage: "backward", action: {
                    albunsViewModel.goToPreviusAlbum()
                })
                .font(.system(size: 30))
                .frame(width: 300, height: 50, alignment: .center)
                
                Button(String(), systemImage: "forward", action: {
                    albunsViewModel.goToNextAlbum()
                })
                .font(.system(size: 30))
                .frame(width: 300, height: 50, alignment: .center)
            }
            Table(tableData, selection: $selection) {
                TableColumn(LocalizedStringKey("text_track")) { music in
                    Text("\(music.track)")
                }
                .width(40)
                .alignment(.trailing)
                TableColumn(LocalizedStringKey("text_title"), value: \.musicTitle)
                TableColumn(LocalizedStringKey("text_duration")) { music in
                    Text(String().secondsToTime(seconds: music.duration))
                }
            }
            .padding()
            .onChange(of: selection) { oldSelected, newSelected in
                albunsViewModel.setIdSelection(selection: (newSelected ?? UUID()))
                let music = albunsViewModel.musicSelected
                musicPlayerViewModel.setMusicSelected(music: music)
            }
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .navigation) {
                MusicPlayerView(musicsPlayerViewModel: musicPlayerViewModel, selection: $selection)
            }
        }
        .onAppear() {
            albunsViewModel.reloadAlbuns()
        }
    }
    

}

#Preview {
    AlbunsView(albunsViewModel: AlbunsViewModel())
}
