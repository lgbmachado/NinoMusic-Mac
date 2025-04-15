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
    
    @Published var directories = [MusicDirectory]()
    
    private var musicFiles = MusicFiles()
    
    init() {
        self.musicFiles.delegate = self
        self.directories = self.musicFiles.directories
        self.musics = self.musicFiles.musics
    }
     
    func addDirectory(dirPath: String) async {
        self.isLoading = true
        await self.musicFiles.addDirectory(dirPath: dirPath.removingPercentEncoding?.replacingOccurrences(of: "file://", with: "") ?? "")
        self.directories = self.musicFiles.directories
        self.musics = self.musicFiles.musics
        self.isLoading = false
    }
    
    func deleteDirectory(selection: UUID) async {
        self.isLoading = true
        if let dir = musicFiles.directories.first(where: { $0.id == selection }) {
            await self.musicFiles.deleteDirectory(dirName: dir.name)
            self.directories = self.musicFiles.directories
            self.musics = self.musicFiles.musics
            self.totalTime = self.musicFiles.totalTime
            self.totalMusics = self.musicFiles.musics.count
            self.isLoading = false
        } else {
            self.isLoading = false
        }

    }
}

extension LibraryViewModel {
    
    func musicLoading(musicsLoaded: Int, totalTime: TimeInterval) {
        self.totalMusics = musicsLoaded
        self.totalTime = totalTime
    }
}
