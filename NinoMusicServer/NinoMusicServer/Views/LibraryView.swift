//
//  LibraryView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 05/08/24.
//

import SwiftUI

struct LibraryView: View {
    @ObservedObject var musicsViewModel: MusicsViewModel
    
    @State private var sortOrder = [KeyPathComparator(\Directory.name)]
    @State private var selection: Directory.ID? = nil
    
    var tableData: [Directory] {
        return musicsViewModel.directories.sorted(using: sortOrder)
    }
    
    var body: some View {
        Table(tableData, selection: $selection, sortOrder: $sortOrder) {
            TableColumn(LocalizedStringKey("text_dirs_registered")) { diretory in
                DirectoryRowView(diretory: diretory)
            }
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .navigation) {
                ToolbarLibraryView(musicsViewModel: musicsViewModel, selection: $selection)
            }
        }
    }
}

// MARK: ToolbarMusicsView
struct ToolbarLibraryView: View {
    @ObservedObject var musicsViewModel: MusicsViewModel
    @Binding var selection: Music.ID?
    
    @State private var showAlert1 = false
    @State private var showAlert2 = false
    @State private var showAlert3 = false
    @State private var showProgress = false
    
    var body: some View {
        HStack {
            Button("", systemImage: "plus.circle", action: {
                self.musicsViewModel.addDirectory()
                Task {
                    await self.musicsViewModel.updateMusicsDatabase()
                }
                showAlert1 = true
            })
            .font(.system(size: 30))
            .buttonStyle(.borderless)
            
            Button("", systemImage: "minus.circle", action: {
                showAlert2 = true
            })
            .font(.system(size: 30))
            .buttonStyle(.borderless)
            
            
            VStack(alignment: .leading, spacing: 6) {
                Text(verbatim: !self.musicsViewModel.isLoading && self.musicsViewModel.totalMusics > 0 ? "Músicas:  \(self.musicsViewModel.totalMusics)" : "")
                    .font(.title3)
                Text(verbatim: !self.musicsViewModel.isLoading  && self.musicsViewModel.totalMusics > 0 ? "Tempo: \(getTotalMusicTime(interval: self.musicsViewModel.totalTime))" : "")
                    .font(.title3)
            }
            .padding(.top, 5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 10)
        .padding(.bottom, 5)
        
        .sheet(isPresented: $showAlert1) {
            showLoadingProgress(musicsViewModel: musicsViewModel)
        }
        
        .confirmationDialog(LocalizedStringKey("text_confirm_dir_exlusion"), isPresented: $showAlert2) {
            Button(LocalizedStringKey("text_yes")) {
                self.musicsViewModel.deleteDirectory(selection: selection ?? UUID())
                Task {
                    await self.musicsViewModel.updateMusicsDatabase()
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
    @ObservedObject var musicsViewModel: MusicsViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            if self.musicsViewModel.isLoading {
                ProgressView()
                    .frame(width: 50, height: 50, alignment: .center)
            } else {
                Image(systemName: "hand.thumbsup")
                    .resizable()
                    .frame(width: 45, height: 45, alignment: .center)
            }
            Text(verbatim: self.musicsViewModel.isLoading ? "Carregando \(self.musicsViewModel.totalMusics) músicas..." : "\(self.musicsViewModel.totalMusics) músicas lidas!")
            Button(LocalizedStringKey("text_ok")) {
                dismiss()
            }
            .frame(width: 100, height: 35, alignment: .center)
            .disabled(self.musicsViewModel.isLoading)
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
    LibraryView(musicsViewModel: MusicsViewModel())
}
