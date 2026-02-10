//
//  TagEditoView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 27/01/25.
//

import SwiftUI

struct TagEditorView: View {
    @ObservedObject var tagEditorViewModel: TagEditorViewModel
    
    @State private var searchTerm: String = ""
    @State var selection: UUID? = nil
    
    @State private var inspectorIsShown: Bool = false
    
    var body: some View {
        TabView {
            MusicsFilesAndFoldersView(tagEditorViewModel: tagEditorViewModel)
                .tabItem {
                    Image(systemName: "")
                    Text("Arquivos e pastas")
                }
            MusicsLibraryView(tagEditorViewModel: tagEditorViewModel)
                .tabItem {
                    Image(systemName: "")
                    Text("Biblioteca")
                }
        }
        .onAppear() {
//            tagEditorViewModel.reloadMusicsFromLibrary()
        }
        .toolbar{
            ToolbarItem(placement: .primaryAction) {
                Button {
                    inspectorIsShown.toggle()
                } label: {
                    Label(LocalizedStringKey("text_show_details"), systemImage: "sidebar.right")
                }
            }
        }
        .inspector(isPresented: $inspectorIsShown) {
            Group {
                MusicDetailsView(tagEditorViewModel: self.tagEditorViewModel)
            }
            .frame(minWidth: 100, maxWidth: .infinity)
        }
        .searchable(text: $searchTerm)
    }
    
}

struct MusicsFilesAndFoldersView: View {
    @ObservedObject var tagEditorViewModel: TagEditorViewModel
    @State private var openFile: Bool = false
    @State private var openFolder: Bool = false
    @State private var showMenu: Bool = false
    
    var body: some View {
        VStack {
            HStack {
                Menu {
                    Button("Adicionar arquivo") {
                        self.AddFile()
                    }
                    Button("Adicionar diretório") {
                        self.AddFolder()
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 32, height: 32)
                }
                .frame(width: 150, height: 10, alignment: .topLeading)
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle)
                .sheet(isPresented: $openFile) {
                    
                }
                .sheet(isPresented: $openFolder) {
                    
                }
                Spacer()
            }
            .padding(.horizontal)
            Table(tagEditorViewModel.musicsFileDir, selection: $tagEditorViewModel.idMusicSelected) {
                TableColumn(LocalizedStringKey("text_file_name")) { (music: Music) in
                    Text(verbatim: "\((music.filePath as NSString).removingPercentEncoding ?? "")")
                }
            }
            .padding()
            .onChange(of: tagEditorViewModel.idMusicSelected) { oldSelected, newSelected in
                tagEditorViewModel.setIdSelection(selection: newSelected ?? UUID())
            }
        }
    }
    
    func AddFile() {
        let dialog = NSOpenPanel()
        dialog.title = "Selecione o arquivo Mp3"
        dialog.showsHiddenFiles = false
        dialog.canChooseFiles = true
        dialog.canChooseDirectories = false
        dialog.allowedContentTypes = [.mp3]
        
        if (dialog.runModal() ==  NSApplication.ModalResponse.OK) {
            if let url = dialog.url {
                self.tagEditorViewModel.AddFile(url: url)
            }
        } else {
            return
        }
    }
    
    func AddFolder() {
        let dialog = NSOpenPanel()
        dialog.title = String(localized: "text_select_dir")
        dialog.showsHiddenFiles = false
        dialog.canChooseFiles = false
        dialog.canChooseDirectories = true
        
        if (dialog.runModal() ==  NSApplication.ModalResponse.OK) {
            if let url = dialog.url {
                self.tagEditorViewModel.AddFolder(url: url)
            }
        }
    }
}


struct MusicsLibraryView: View {
    @ObservedObject var tagEditorViewModel: TagEditorViewModel
    @State private var sortOrder = [KeyPathComparator(\Music.musicTitle)]
    
    var body: some View {
        Table(tagEditorViewModel.musicsLibrary, selection: $tagEditorViewModel.idMusicSelected, sortOrder: $sortOrder) {
            TableColumn(LocalizedStringKey("text_file_name")) { (music: Music) in
                Text(verbatim: "\(((music.filePath as NSString).lastPathComponent).removingPercentEncoding ?? "")")
            }
            TableColumn(LocalizedStringKey("text_title"), value: \.musicTitle)
            TableColumn(LocalizedStringKey("text_artist"), value: \.artist)
                .width(150)
            TableColumn(LocalizedStringKey("text_album"), value: \.album)
            TableColumn(LocalizedStringKey("text_track")) { music in
                Text("\(music.track)")
            }
            .width(40)
            TableColumn(LocalizedStringKey("text_year"), value: \.year)
                .width(50)
            TableColumn(LocalizedStringKey("text_genre"), value: \.genre)
                .width(100)
        }
        .padding()
        .onChange(of: tagEditorViewModel.idMusicSelected) { oldSelected, newSelected in
            tagEditorViewModel.setIdSelection(selection: newSelected ?? UUID())
        }
    }
}

