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
    
    @State private var sortOrder = [KeyPathComparator(\Directory.name)]
    @State private var selection: Directory.ID? = nil
    
    var tableData: [Directory] {
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
                Text(verbatim: !self.libraryViewModel.isLoading && self.libraryViewModel.totalMusics > 0 ? "Músicas:  \(self.libraryViewModel.totalMusics)" : "")
                    .font(.title3)
                Text(verbatim: !self.libraryViewModel.isLoading  && self.libraryViewModel.totalMusics > 0 ? "Tempo: \(getTotalMusicTime(interval: self.libraryViewModel.totalTime))" : "")
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
    
    func getTotalMusicTime(interval: TimeInterval) -> String {
        
        var result = ""
        var seconds = Int(interval)
        
        var months: Int = 0
        if seconds >= 2592000 {
            months = seconds / 2592000
            if months > 0 {
                result += "\(months) \(months == 1 ? "mês" : "meses") "
            }
            seconds -= months * 2592000
        }
        
        var days: Int = 0
        if seconds >= 86400 {
            days = seconds / 86400
            if days > 0 {
                result += "\(days) \(days == 1 ? "dia" : "dias") "
            }
            seconds -= days * 86400
        }
        
        var hours: Int = 0
        if seconds >= 3600 {
            hours = seconds / 3600
            if hours > 0 {
                result += "\(hours) \(hours == 1 ? "hora" : "horas") "
            }
            seconds -= hours * 3600
        }
        
        var minutes: Int = 0
        if seconds >= 60 {
            minutes = seconds / 60
            if minutes > 0 {
                result += "\(minutes) \(minutes == 1 ? "minuto" : "minutos") "
            }
            seconds -= minutes * 60
        }
        if seconds > 0 {
            result += "e \(seconds) \(seconds == 1 ? "segundo" : "segundos")"
        }
        return result
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
    LibraryView(musicsViewModel: MusicsViewModel(), libraryViewModel: LibraryViewModel())
}
