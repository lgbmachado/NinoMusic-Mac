//
//  MusicsViewModel.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 12/03/25.
//

import SwiftUI
import SwiftData

class MusicsViewModel: BaseViewModel {
    @Published var musics: [Music] = []
    
    override func onNavigate(kind: NavigationKind, originNotification: MusicContentViewType?) {
        if originNotification == .musics {
            let searchCount = kind == .next ? musicSelected.seq + 1 : musicSelected.seq - 1
            if let selected = self.musics.first(where: {$0.seq == searchCount}) {
                self.idMusicSelected = selected.id
                self.musicSelected = selected
                musicPlayerViewModel.setMusicSelected(music: selected)
                musicPlayerViewModel.originCurrentMusic = .musics
            }
        }
    }
    
    func reloadMusics() {
        let descriptor = FetchDescriptor<Music>(
            sortBy: [
                SortDescriptor(\.musicTitle),
                SortDescriptor(\.artist)
            ]
        )
        
        do {
            let fetchedMusics = try modelContext.fetch(descriptor)
            var seq = 0
            self.musics = fetchedMusics.map { music in
                seq += 1
                music.seq = seq
                return music
            }
        } catch {
            print("Erro ao buscar músicas: \(error)")
            self.musics = []
        }
    }
    
    func setIdSelection(selection: Music.ID) {
        self.idMusicSelected = selection
        if let item = self.musics.first(where: { $0.id == self.idMusicSelected }) {
            self.idMusicSelected = item.id
            self.musicSelected = item
            self.fileSelected = String((item.filePath as NSString).lastPathComponent).removingPercentEncoding?.replacingOccurrences(of: "file://", with: "") ?? ""
        } else {
            self.musicSelected = Music.emptyMusic
        }
    }
    
}
