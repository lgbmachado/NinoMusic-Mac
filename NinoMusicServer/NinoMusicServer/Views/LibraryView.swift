//
//  LibraryView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 05/08/24.
//

import SwiftUI

struct LibraryView: View {
    @ObservedObject var musicsViewModel: MusicsViewModel
    @ObservedObject var libraryViewModel: LibraryViewModel
    
    @State private var sortOrder = [KeyPathComparator(\MusicDirectory.name)]
    @State private var selection: MusicDirectory.ID? = nil
    
    var tableData: [MusicDirectory] {
        return libraryViewModel.directories.sorted(using: sortOrder)
    }
    
    var body: some View {
        Table(tableData, selection: $selection, sortOrder: $sortOrder) {
            TableColumn(LocalizedStringKey("text_dirs_registered")) { diretory in
                DirectoryRowView(diretory: diretory)
            }
        }
        .onChange(of: selection) { oldSelected, newSelected in

        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .navigation) {
                ToolbarLibraryView(musicsViewModel: musicsViewModel, libraryViewModel: libraryViewModel, selection: $selection)
            }
        }
    }
}

// MARK: ToolbarMusicsView
struct ToolbarLibraryView: View {
    @ObservedObject var musicsViewModel: MusicsViewModel
    @ObservedObject var libraryViewModel: LibraryViewModel
    
    @Binding var selection: Music.ID?
    
    @State private var showAlert1 = false
    @State private var showAlert2 = false
    @State private var showAlert3 = false
    @State private var showProgress = false
    
    var body: some View {
        HStack {
            Button(String(), systemImage: "plus.circle", action: {
                self.addDiretory()
            })
            .font(.system(size: 30))
            .buttonStyle(.borderless)
            
            Button(String(), systemImage: "minus.circle", action: {
                if self.selection != nil {
                    showAlert2 = true
                }
            })
            .font(.system(size: 30))
            .buttonStyle(.borderless)
            
            
            VStack(alignment: .leading, spacing: 6) {
                Text(verbatim: self.libraryViewModel.totalMusics > 0 ? "Músicas:  \(self.libraryViewModel.totalMusics)" : "")
                    .font(.title3)
                Text(verbatim: self.libraryViewModel.totalMusics > 0 ? "Tempo: \( self.libraryViewModel.totalTime.timeIntervalToString() ))" : "")
                    .font(.title3)
            }
            .padding(.top, 5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 10)
        .padding(.bottom, 5)
        
        .sheet(isPresented: $showAlert1) {
            showLoadingProgress(libraryViewModel: libraryViewModel)
        }
        
        .confirmationDialog(LocalizedStringKey("text_confirm_dir_exlusion"), isPresented: $showAlert2) {
            Button(LocalizedStringKey("text_yes")) {
                Task {
                    await self.libraryViewModel.deleteDirectory(selection: selection ?? UUID())
                    showAlert3 = true
                }
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
    
    func addDiretory() {
        let dialog = NSOpenPanel()
        dialog.title = String(localized: "text_select_dir")
        dialog.showsHiddenFiles = false;
        dialog.canChooseFiles = false;
        dialog.canChooseDirectories = true;
        
        if (dialog.runModal() ==  NSApplication.ModalResponse.OK) {
            if let url = dialog.url {
                Task {
                    await self.libraryViewModel.addDirectory(dirPath: url.path())
                }
                showAlert1 = true
            }
        } else {
            return
        }
    }
}



struct showLoadingProgress: View {
    @ObservedObject var libraryViewModel: LibraryViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            if self.libraryViewModel.isLoading {
                ProgressView()
                    .frame(width: 50, height: 50, alignment: .center)
            } else {
                Image(systemName: "hand.thumbsup")
                    .resizable()
                    .frame(width: 45, height: 45, alignment: .center)
            }
            Text(verbatim: self.libraryViewModel.isLoading ? "Carregando \(self.libraryViewModel.totalMusics) músicas..." : "\(self.libraryViewModel.totalMusics) músicas lidas!")
            Button(LocalizedStringKey("text_ok")) {
                dismiss()
            }
            .frame(width: 100, height: 35, alignment: .center)
            .disabled(self.libraryViewModel.isLoading)
        }
        .frame(maxWidth: 300, maxHeight: 200, alignment: .center)
        .padding()
    }
}

struct DirectoryRowView: View {
    var diretory: MusicDirectory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Label(diretory.name, systemImage: "play.fill")
                .foregroundColor(.primary)
                .font(.headline)
            Label(diretory.path, systemImage: "folder")
                .foregroundColor(.secondary)
                .font(.subheadline)
                .padding(.leading, 20)
            Label("\(diretory.musicCount) musica(s).", systemImage: "arrow.counterclockwise")
                .foregroundColor(.secondary)
                .font(.subheadline)
                .padding(.leading, 20)
            Label(diretory.totalTime.timeIntervalToString(), systemImage: "clock")
                .foregroundColor(.secondary)
                .font(.subheadline)
                .padding(.leading, 20)
        }
    }
}

#Preview {
    LibraryView(musicsViewModel: MusicsViewModel(musicPlayerViewModel: MusicPlayerViewModel()), libraryViewModel: LibraryViewModel())
}
