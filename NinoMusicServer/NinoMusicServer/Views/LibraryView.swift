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
    @State private var showAlert1 = false
    @State private var showAlert2 = false
    @State private var showAlert3 = false
    @State private var showProgress = false
    
    var body: some View {
        Table(tableData, selection: $selection, sortOrder: $sortOrder) {
            TableColumn(LocalizedStringKey("text_dirs_registered")) { diretory in
                DirectoryRowView(diretory: diretory)
            }
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .navigation) {
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
                    
                    Spacer(minLength: 30)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(verbatim: "\(self.musicsViewModel.totalMusics) músicas lidas")
                            .font(.title3)
                        Text(verbatim: "")
                            .font(.caption2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 10)
                .padding(.bottom, 5)
            }
        }
        .alert(LocalizedStringKey("text_success_dir_included"), isPresented: $showAlert1) {
            Button(LocalizedStringKey("text_ok"), role: .cancel) { }
        }
        .dialogIcon(Image(systemName: "info.circle"))
        
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
