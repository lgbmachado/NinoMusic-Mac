//
//  AlbunsView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 01/04/25.
//

import SwiftUI

struct AlbunsView: View {
    @ObservedObject var musicPlayerViewModel: MusicPlayerViewModel
    @ObservedObject var albunsViewModel: AlbunsViewModel

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
            Text(verbatim: String(albunsViewModel.albumSelected.year))
                .font(.caption2)
            Text(verbatim: albunsViewModel.albumSelected.genre)
                .font(.caption2)
            HStack {
                Button(String(), systemImage: "backward", action: {
                    albunsViewModel.goToPreviusAlbum()
                })
                .keyboardShortcut(.leftArrow, modifiers: [])
                .help("Álbum anterior (←)")
                .font(.system(size: 30))
                .frame(width: 300, height: 50, alignment: .center)
                
                Button(String(), systemImage: "forward", action: {
                    albunsViewModel.goToNextAlbum()
                })
                .keyboardShortcut(.rightArrow, modifiers: [])
                .help("Próximo álbum (→)")
                .font(.system(size: 30))
                .frame(width: 300, height: 50, alignment: .center)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(albunsViewModel.availableAlbumLetters, id: \.self) { letter in
                        Button(letter, action: {
                            albunsViewModel.goToAlbumStartingWith(letter: letter)
                        })
                        .help("Ir para álbuns iniciados com \(letter)")
                    }
                }
            }
            .padding(.horizontal)
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
                TableColumn(LocalizedStringKey("text_lyric")) { music in
                    if music.hasLyric {
                        Image(systemName: "music.note.tv")
                    }
                }
                .width(50)
                TableColumn(LocalizedStringKey("text_last_update")) { music in
                    Text(music.lastUpdate.formatted(date: .numeric, time: .shortened))
                }
                TableColumn(LocalizedStringKey("text_last_execution")) { music in
                    // LastExecution is stored as -1 when the music was never played
                    if music.lastExecution.timeIntervalSince1970 >= 0 {
                        Text(music.lastExecution.formatted(date: .numeric, time: .shortened))
                    }
                }
                TableColumn(LocalizedStringKey("text_count_execution")) { music in
                    Text("\(music.countExecution)")
                }
                .alignment(.trailing)
            }
            .padding()
            .onChange(of: albunsViewModel.idMusicSelected) { oldSelected, newSelected in
                albunsViewModel.setIdSelection(selection: (newSelected ?? UUID()))
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
    }
}

#Preview {
    AlbunsView(musicPlayerViewModel: MusicPlayerViewModel(), albunsViewModel: AlbunsViewModel(musicPlayerViewModel: MusicPlayerViewModel()))
}
