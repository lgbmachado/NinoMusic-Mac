//
//  LibraryViewModel.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 14/03/25.
//

import Foundation

class LibraryViewModel: ObservableObject, MusicFilesDelegate {
    
    @Published var musics: [Music] = []
    @Published var totalMusics: Int = 0
    @Published var totalTime: TimeInterval = 0
    @Published var isLoading: Bool = false
    
    @Published var directories = Directories().dirs
    
    private var musicFiles = MusicFiles()
    
    init() {
        self.musicFiles.delegate = self
    }
    
    func loadMusics() {
        let musicDb = Database()
        self.musics = musicDb.getMusics()
        self.totalTime = 0
        for music in musics {
            self.totalTime += Double(music.duration)
        }
        self.totalMusics = musics.count
    }
    
 
    func addDirectory(diretory: String) {
        self.directories.append(Directory(name: "Dir \(directories.count + 1)",
                                     path: diretory))
        Directories().dirs = directories
        let musicDb = Database()
        musicDb.cleanTables()
    }
    
    func deleteDirectory(selection: UUID) {
        if directories.count > 0 {
            let modstations = directories.filter{ $0.id != selection}
            Directories().dirs = modstations
            directories = Directories().dirs
            let musicDb = Database()
            musicDb.cleanTables()
        }
    }
    
    func updateMusicsDatabase() async {
        self.totalMusics = 0
        self.totalTime = 0
        self.isLoading = true
        for i in 0..<Directories().dirs.count {
            await self.musicFiles.loadMusics(path: Directories().dirs[i].path) { musicsLoaded in
            }
        }
        loadMusics()
        self.isLoading = false
    }
}

extension LibraryViewModel {
    
    func musicLoading(musicsLoaded: Int, totalTime: TimeInterval) {
        self.totalMusics = musicsLoaded
        self.totalTime = totalTime
    }
}
