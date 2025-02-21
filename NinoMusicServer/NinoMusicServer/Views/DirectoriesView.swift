//
//  DirectoriesView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 05/08/24.
//

import SwiftUI

struct DirectoriesView: View, MusicFilesDelegate {
    func musicLoading(musicsLoaded: Int) {
        
    }
    @State private var directories = Directories().dirs
    @State private var sortOrder = [KeyPathComparator(\Directory.name)]
    @State private var selection: Directory.ID? = nil
    
    @Binding var musics: Musics
    
    var musicFiles = MusicFiles()
    
    var tableData: [Directory] {
        return directories.sorted(using: sortOrder)
    }
    @State private var showAlert1 = false
    @State private var showAlert2 = false
    @State private var showAlert3 = false
    @State private var showProgress = false
    
    var body: some View {
        VStack {
            Table(tableData, selection: $selection, sortOrder: $sortOrder) {
                TableColumn(LocalizedStringKey("text_dirs_registered")) { diretory in
                    DirectoryRowView(diretory: diretory)
                }
            }
            HStack {
                Button {
                    AddDirectory()
                    Task {
                        await UpdateMusicsDatabase()
                    }
                    showAlert1 = true
                } label: {
                    Image(systemName: "plus.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(.borderless)
                
                
                Button {
                    showAlert2 = true
                } label: {
                    Image(systemName: "minus.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(.borderless)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 10)
            .padding(.bottom, 5)
        }
        
        .alert(LocalizedStringKey("text_success_dir_included"), isPresented: $showAlert1) {
            Button(LocalizedStringKey("text_ok"), role: .cancel) { }
        }
        .dialogIcon(Image(systemName: "info.circle"))
        
        .confirmationDialog(LocalizedStringKey("text_confirm_dir_exlusion"), isPresented: $showAlert2) {
            Button(LocalizedStringKey("text_yes")) {
                DeleteDirectory()
                Task {
                    await UpdateMusicsDatabase()
                }
                showAlert3 = true
            }
            Button(LocalizedStringKey("text_no"), role: .cancel) {
            }
        }
        .dialogIcon(Image(systemName: "exclamationmark.triangle"))
        
        .alert(LocalizedStringKey("text_success_dir_excluded"), isPresented: $showAlert3) {
            Button(LocalizedStringKey("text_ok"), role: .cancel) { }
        }
        .dialogIcon(Image(systemName: "info.circle"))
    }
    
    func AddDirectory() {
        let dialog = NSOpenPanel()
        dialog.title = String(localized: "text_select_dir")
        dialog.showsResizeIndicator = true;
        dialog.showsHiddenFiles = false;
        dialog.canChooseFiles = false;
        dialog.canChooseDirectories = true;
        
        if (dialog.runModal() ==  NSApplication.ModalResponse.OK) {
            showProgress = true
            if let result = dialog.url {
                directories.append(Directory(name: "Dir \(directories.count + 1)",
                                             path: result.path))
                Directories().dirs = directories
                let musicDb = Database()
                musicDb.cleanTables()
            }
        } else {
            return
        }
    }
    
    func DeleteDirectory() {
        if directories.count > 0 {
            let modstations = directories.filter{ $0.id != selection}
            Directories().dirs = modstations
            directories = Directories().dirs
            let musicDb = Database()
            musicDb.cleanTables()
        }
    }
    
    func UpdateMusicsDatabase() async {
        let musicFiles = MusicFiles()
        for i in 0..<Directories().dirs.count {
            await musicFiles.loadMusics(path: Directories().dirs[i].path) { musicsLoaded in
                if let musicsLoaded = musicsLoaded {
                    DispatchQueue.main.async {
                        print("\(musicsLoaded) musicas lidas.")
                        let musicDb = Database()
                        let musicsTemp = Musics()
                        musicsTemp.musics = musicDb.getMusics()
                        musics = musicsTemp
                    }
                }
            }
        }
    }
}

struct DirectoryRowView: View {
    var diretory: Directory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(diretory.name)
                .foregroundColor(.primary)
                .font(.headline)
            HStack(spacing: 3) {
                Label(diretory.path, systemImage: "folder")
            }
            .foregroundColor(.secondary)
            .font(.subheadline)
        }
    }
}

#Preview {
    DirectoriesView(musics: .constant(Musics()))
}
