//
//  AlbunsView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 01/04/25.
//

import SwiftUI

struct AlbunsView: View {
    @StateObject var musicPlayerViewModel: MusicPlayerViewModel
    @StateObject var albunsViewModel: AlbunsViewModel

    var body: some View {
        VStack {
            Image(nsImage: Id3TagUtils.getImageCover(path: albunsViewModel.filePathCover) ?? NSImage())
                .resizable()
                .frame(width: 250, height: 250, alignment: .bottom)
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
            Table(albunsViewModel.albumSelected.musics, selection: $albunsViewModel.idMusicSelected) {
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
            .onChange(of: albunsViewModel.idMusicSelected) { oldSelected, newSelected in
                albunsViewModel.setIdSelection(originNotification: .albuns, selection: (newSelected ?? UUID()))
                let music = albunsViewModel.musicSelected
                musicPlayerViewModel.setMusicSelected(music: music)
                musicPlayerViewModel.originCurrentMusic = .albuns
            }
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .navigation) {
                MusicPlayerView(musicsPlayerViewModel: musicPlayerViewModel, selection: $albunsViewModel.idMusicSelected)
            }
        }
        .onAppear() {
            albunsViewModel.reloadAlbuns()
            albunsViewModel.albumSelected = Album.emptyAlbum
            albunsViewModel.goToNextAlbum()
        }
    }
}

#Preview {
    AlbunsView(musicPlayerViewModel: MusicPlayerViewModel(), albunsViewModel: AlbunsViewModel(musicPlayerViewModel: MusicPlayerViewModel()))
}
