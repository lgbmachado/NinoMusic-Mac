//
//  MusicDetailsView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 24/01/25.
//

import SwiftUI
import ID3TagEditor

struct MusicDetailsView: View {
    @ObservedObject var tagEditorViewModel: TagEditorViewModel
    
    var body: some View {
        VStack {
            TabView {
                TagView(tagEditorViewModel: tagEditorViewModel)
                    .tabItem {
                        Image(systemName: "tag")
                        Text(LocalizedStringKey("text_tag"))
                    }
                FileView(tagEditorViewModel: tagEditorViewModel)
                    .tabItem {
                        Image(systemName: "folder")
                        Text(LocalizedStringKey("text_file"))
                    }
            }
        }
    }
}

struct TagView: View {
    @ObservedObject var tagEditorViewModel: TagEditorViewModel
    
    @State private var successSaveTag = false
    @State private var finishSaveTag = false
    
    @State private var finishSaveCoverImage = false
    @State private var successSaveCoverImage = false
    
    @State private var pathCoverImage = String()
    
    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.zeroSymbol = ""
        return formatter
    }()
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Capitalização: **\(tagEditorViewModel.selectedCase.description)**")
                    .font(.subheadline)
                    .padding(.bottom, 10)
                Text(LocalizedStringKey("text_music"))
                    .font(.caption2)
                    .padding(.bottom, -7)
                TextField(
                    LocalizedStringKey("text_music"),
                    text: Binding(
                        get: { tagEditorViewModel.musicSelectedDraft.musicTitle },
                        set: { newValue in
                            tagEditorViewModel.musicSelectedDraft.musicTitle = newValue
                        }
                    ).formattedText(self.tagEditorViewModel.selectedCase),
                    prompt: Text(LocalizedStringKey("text_music"))
                )
                
                Text(LocalizedStringKey("text_artist"))
                    .font(.caption2)
                    .padding(.bottom, -7)
                TextField(
                    LocalizedStringKey("text_artist"),
                    text: Binding(
                        get: { tagEditorViewModel.musicSelectedDraft.artist },
                        set: { newValue in
                            tagEditorViewModel.musicSelectedDraft.artist = newValue
                        }
                    ).formattedText(self.tagEditorViewModel.selectedCase),
                    prompt: Text(LocalizedStringKey("text_artist"))
                )
                
                Text(LocalizedStringKey("text_album"))
                    .font(.caption2)
                    .padding(.bottom, -7)
                TextField(
                    LocalizedStringKey("text_album"),
                    text: Binding(
                        get: { tagEditorViewModel.musicSelectedDraft.album },
                        set: { newValue in
                            tagEditorViewModel.musicSelectedDraft.album = newValue
                        }
                    ).formattedText(self.tagEditorViewModel.selectedCase),
                    prompt: Text(LocalizedStringKey("text_album"))
                )
                
                Text(LocalizedStringKey("text_year"))
                    .font(.caption2)
                    .padding(.bottom, -7)
                TextField(LocalizedStringKey("text_year"),
                          text: Binding(
                            get: { String(tagEditorViewModel.musicSelectedDraft.year) },
                                                        set: { newValue in
                                                                tagEditorViewModel.musicSelectedDraft.year = Int(newValue) ?? 0
                                                        }
                          ),
                          prompt: Text(LocalizedStringKey("text_year"))
                )
                
                Text(LocalizedStringKey("text_track"))
                    .font(.caption2)
                    .padding(.bottom, -7)
                
                Stepper(
                    "\(tagEditorViewModel.musicSelectedDraft.track)",
                    value: Binding(
                        get: { tagEditorViewModel.musicSelectedDraft.track },
                        set: { newValue in
                            tagEditorViewModel.musicSelectedDraft.track = newValue
                        }
                    )
                )
                
                Text(LocalizedStringKey("text_genre"))
                    .font(.caption2)
                    .padding(.bottom, -7)
                ComboBox(
                    text: Binding(
                        get: { tagEditorViewModel.musicSelectedDraft.genre },
                        set: { newValue in
                            tagEditorViewModel.musicSelectedDraft.genre = newValue
                        }
                    ).formattedText(self.tagEditorViewModel.selectedCase),
                    items: tagEditorViewModel.genresAvaiables,
                    placeholder: String(localized: "text_genre")
                )
                .frame(width: 200)
                
                Text(LocalizedStringKey("text_album_cover"))
                    .font(.caption2)
                    .padding(.bottom, -7)
                HStack {
                    Spacer()
                    Button(action: {
                        loadCoverImage()
                    }) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .disabled(tagEditorViewModel.fileSelected.isEmpty)
                    
                    Button(action: {
                        saveCoverImage()
                    }) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .alert(successSaveCoverImage ?  "Imagem da capa do álbum salva com sucesso." : "Falha ao salvar imagem da capa do álbum.", isPresented: $finishSaveCoverImage) {
                        Button(LocalizedStringKey("text_ok"), role: .cancel) { }
                    }
                }
                
                Image(nsImage: Id3TagUtils.getImageCover(path: self.tagEditorViewModel.musicSelectedDraft.filePath) ?? NSImage())
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 300, alignment: .bottom)
                    .border(.black)
                
                Text("Letra")
                    .font(.caption2)
                    .padding(.bottom, -7)
                TextEditor(text: $tagEditorViewModel.musicLyricDraft)
                    .disabled(false)
                    .font(.body)
                    .padding(4)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
                    .frame(maxWidth: .infinity, minHeight: 300, alignment: .bottom)
                            
                
                Spacer()
                HStack {
                    Spacer()
                    Button("Salvar") {
                        successSaveTag = self.tagEditorViewModel.SetMusicTags(coverImagePath: pathCoverImage)
                        if successSaveTag {
                            self.tagEditorViewModel.musicSelected = self.tagEditorViewModel.musicSelectedDraft
                            self.tagEditorViewModel.musicLyric = self.tagEditorViewModel.musicLyricDraft
                        }
                        finishSaveTag = true
                    }
                    .padding()
                    .disabled(!(self.tagEditorViewModel.musicSelectedDraft != self.tagEditorViewModel.musicSelected || self.tagEditorViewModel.musicLyricDraft != self.tagEditorViewModel.musicLyric))
                    .alert(successSaveTag ? "Novas informações no arquivo de música salvas com sucesso." : "Falha ao salvar novas informações no arquivo de música.", isPresented: $finishSaveTag) {
                        Button(LocalizedStringKey("text_ok"), role: .cancel) { }
                    }
                    
                    Button("Desfazer", role: .cancel) {
                        self.tagEditorViewModel.musicSelectedDraft = self.tagEditorViewModel.musicSelected
                        self.tagEditorViewModel.musicLyricDraft = self.tagEditorViewModel.musicLyric
                    }
                    .padding()
                    .disabled(!(self.tagEditorViewModel.musicSelectedDraft != self.tagEditorViewModel.musicSelected || self.tagEditorViewModel.musicLyricDraft != self.tagEditorViewModel.musicLyric))
                    Spacer()
                }
                
            }
        }
    }
    
    private func loadCoverImage() {
        let dialog = NSOpenPanel()
        dialog.title = "Selecione a imagem da capa"
        dialog.showsHiddenFiles = false
        dialog.canChooseFiles = true
        dialog.canChooseDirectories = false
        dialog.allowedContentTypes = [.jpeg, .png]
        
        if (dialog.runModal() ==  NSApplication.ModalResponse.OK) {
            if let url = dialog.url {
                self.pathCoverImage = url.absoluteString
            }
        } else {
            return
        }
        return
    }
    
    private func saveCoverImage() {
        let dialog = NSSavePanel()
        dialog.title = "Selecione o nome do arquivo"
        dialog.showsHiddenFiles = false
        dialog.allowedContentTypes = [.jpeg, .png]
        
        if (dialog.runModal() ==  NSApplication.ModalResponse.OK) {
            if let url = dialog.url {
                self.successSaveCoverImage = self.tagEditorViewModel.saveCover(coverImageUrl: url)
            }
        } else {
            self.finishSaveCoverImage = false
        }
        self.finishSaveCoverImage = true
    }
}

struct FileView: View {
    @ObservedObject var tagEditorViewModel: TagEditorViewModel

    @AppStorage("FileNameMask") private var fileNameMask = "{track:02} - {artist} - {title}"
    @State private var didRenameFile = false
    @State private var showRenameResult = false
    @State private var selectedLibraryPath = ""
    @State private var didExportFile = false
    @State private var showExportResult = false

    private var matchingFields: [String] {
        guard let openingBrace = fileNameMask.lastIndex(of: "{") else {
            return []
        }

        let queryStart = fileNameMask.index(after: openingBrace)
        let query = String(fileNameMask[queryStart...]).lowercased()
        guard !query.contains("}") else {
            return []
        }

        return TagEditorViewModel.fileNameMaskFields.filter {
            $0.dropFirst().lowercased().hasPrefix(query)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Nome atual")
                .font(.caption2)
                .padding(.bottom, -7)
            TextField(LocalizedStringKey("text_file_name"), text: $tagEditorViewModel.fileSelected)
                .disabled(true)

            Text("Máscara do nome")
                .font(.caption2)
                .padding(.top, 8)
                .padding(.bottom, -7)
            HStack {
                TextField("{track:02} - {artist} - {title}", text: $fileNameMask)
                Menu {
                    ForEach(TagEditorViewModel.fileNameMaskFields, id: \.self) { field in
                        Button(field) {
                            insert(field)
                        }
                    }
                } label: {
                    Image(systemName: "plus.circle")
                }
                .help("Inserir campo da máscara")
            }

            if !matchingFields.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(matchingFields, id: \.self) { field in
                        Button(field) {
                            completeCurrentField(with: field)
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 2)
                    }
                }
                .font(.caption)
                .padding(6)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            Text("Nome gerado")
                .font(.caption2)
                .padding(.top, 8)
                .padding(.bottom, -7)
            Text(tagEditorViewModel.fileNamePreview(mask: fileNameMask))
                .textSelection(.enabled)
                .foregroundStyle(.secondary)

            HStack {
                Spacer()
                Button {
                    didRenameFile = tagEditorViewModel.renameSelectedMusicFile(using: fileNameMask)
                    showRenameResult = true
                } label: {
                    Label("Renomear arquivo", systemImage: "pencil")
                }
                .disabled(tagEditorViewModel.fileNamePreview(mask: fileNameMask).isEmpty || tagEditorViewModel.musicSelected.filePath.isEmpty)
                .alert(didRenameFile ? "Arquivo renomeado com sucesso." : "Não foi possível renomear o arquivo.", isPresented: $showRenameResult) {
                    Button(LocalizedStringKey("text_ok"), role: .cancel) { }
                }
            }

            Divider()
                .padding(.vertical, 6)

            Text("Exportar para biblioteca")
                .font(.caption2)
                .padding(.bottom, -7)
            Picker("Biblioteca", selection: $selectedLibraryPath) {
                Text("Selecione uma biblioteca").tag("")
                ForEach(tagEditorViewModel.libraryDirectories) { library in
                    Text(library.name.isEmpty ? library.path : library.name)
                        .tag(library.path)
                }
            }

            if let selectedLibrary = tagEditorViewModel.libraryDirectories.first(where: { $0.path == selectedLibraryPath }) {
                Text("\(selectedLibrary.path)/\(tagEditorViewModel.musicSelectedDraft.artist)/\(tagEditorViewModel.musicSelectedDraft.album)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }

            HStack {
                Spacer()
                Button {
                    Task {
                        didExportFile = await tagEditorViewModel.exportSelectedMusic(to: selectedLibraryPath)
                        showExportResult = true
                    }
                } label: {
                    Label("Exportar arquivo", systemImage: "square.and.arrow.up")
                }
                .disabled(selectedLibraryPath.isEmpty || tagEditorViewModel.musicSelected.filePath.isEmpty)
                .alert(didExportFile ? "Arquivo exportado para a biblioteca." : "Não foi possível exportar o arquivo.", isPresented: $showExportResult) {
                    Button(LocalizedStringKey("text_ok"), role: .cancel) { }
                }
            }
            Spacer()
        }
        .onAppear {
            tagEditorViewModel.loadLibraryDirectories()
            if selectedLibraryPath.isEmpty {
                selectedLibraryPath = tagEditorViewModel.libraryDirectories.first?.path ?? ""
            }
        }
    }

    private func insert(_ field: String) {
        fileNameMask += field
    }

    private func completeCurrentField(with field: String) {
        guard let openingBrace = fileNameMask.lastIndex(of: "{") else {
            insert(field)
            return
        }

        fileNameMask.replaceSubrange(openingBrace..., with: field)
    }
}
