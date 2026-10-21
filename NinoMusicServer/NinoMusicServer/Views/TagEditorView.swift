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
    @State private var selectedMusicID: Music.ID?
    @State private var sortOrder = [KeyPathComparator(\Music.filePath)]
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
                        .frame(width: 64, height: 64, alignment: .center)
                }
                .frame(width: 150, height: 10, alignment: .topLeading)
                .buttonStyle(.borderedProminent)
                .sheet(isPresented: $openFile) {
                    
                }
                .sheet(isPresented: $openFolder) {
                    
                }
                Spacer()
            }
            .padding(.horizontal)
            Table(sortedMusics, selection: $selectedMusicID, sortOrder: $sortOrder) {
                TableColumn(LocalizedStringKey("text_file_name"), value: \.filePath)
                TableColumn(LocalizedStringKey("text_title"), value: \.musicTitle)
                TableColumn(LocalizedStringKey("text_artists"), value: \.artist)
                TableColumn(LocalizedStringKey("text_album"), value: \.album)
                TableColumn(LocalizedStringKey("text_track"), value: \.trackDisplay, comparator: .localizedStandard)
                TableColumn(LocalizedStringKey("text_year"), value: \.yearDisplay, comparator: .localizedStandard)
                TableColumn(LocalizedStringKey("text_genre"), value: \.genre)
            }
            .padding()
            .onChange(of: selectedMusicID) { _, newSelected in
                guard let newSelected else { return }
                tagEditorViewModel.setIdFilesSelection(selection: newSelected)
            }
        }
    }

    private var sortedMusics: [Music] {
        tagEditorViewModel.musicsFileDir.sorted(using: sortOrder)
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
                Task { await self.tagEditorViewModel.AddFile(url: url) }
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
                Task { await self.tagEditorViewModel.AddFolder(url: url) }
            }
        }
    }
}


struct MusicsLibraryView: View {
    @ObservedObject var tagEditorViewModel: TagEditorViewModel
    @State private var selectedMusicID: Music.ID?
    @State private var sortOrder = [KeyPathComparator(\Music.musicTitle)]

    private var sortedMusics: [Music] {
        tagEditorViewModel.musicsLibrary.sorted(using: sortOrder)
    }
    
    var body: some View {
        Table(sortedMusics, selection: $selectedMusicID, sortOrder: $sortOrder) {
            TableColumn(LocalizedStringKey("text_file_name")) { (music: Music) in
                Text(verbatim: "\(((music.filePath as NSString).lastPathComponent).removingPercentEncoding ?? "")")
            }
            TableColumn(LocalizedStringKey("text_title"), value: \.musicTitle)
            TableColumn(LocalizedStringKey("text_artist"), value: \.artist)
                .width(150)
            TableColumn(LocalizedStringKey("text_album"), value: \.album)
            TableColumn(LocalizedStringKey("text_track"), value: \.trackDisplay, comparator: .localizedStandard)
            .width(40)
            TableColumn(LocalizedStringKey("text_year"), value: \.yearDisplay, comparator: .localizedStandard)
                .width(50)
            TableColumn(LocalizedStringKey("text_genre"), value: \.genre)
                .width(100)
        }
        .padding()
        .onChange(of: selectedMusicID) { _, newSelected in
            guard let newSelected else { return }
            tagEditorViewModel.setIdLibrarySelection(selection: newSelected)
        }
    }
}

private extension Music {
    var trackDisplay: String { String(track) }
    var yearDisplay: String { String(year) }
}

