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
                ExportView(tagEditorViewModel: tagEditorViewModel)
                    .tabItem {
                        Image(systemName: "folder")
                        Text("Exportar")
                    }
            }
        }
    }
}

struct TagView: View {
    @ObservedObject var tagEditorViewModel: TagEditorViewModel
    @AppStorage("DiscogsUserToken") private var discogsUserToken = ""
    
    @State private var successSaveTag = false
    @State private var finishSaveTag = false
    @State private var showDiscogsResults = false
    
    @State private var finishSaveCoverImage = false
    @State private var successSaveCoverImage = false
    
    @State private var pathCoverImage = String()
    @State private var coverImage = NSImage()
    
    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.zeroSymbol = ""
        return formatter
    }()
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Capitalização: **\(tagEditorViewModel.selectedCaseTag.description)**")
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
                    ).formattedText(self.tagEditorViewModel.selectedCaseTag),
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
                    ).formattedText(self.tagEditorViewModel.selectedCaseTag),
                    prompt: Text(LocalizedStringKey("text_artist"))
                )

                Text("Discogs")
                    .font(.caption2)
                    .padding(.bottom, -7)
                HStack {
                    SecureField("Token do Discogs", text: $discogsUserToken)
                    Button {
                        showDiscogsResults = true
                        Task {
                            await tagEditorViewModel.searchDiscogsAlbums()
                        }
                    } label: {
                        Label("Buscar álbuns", systemImage: "magnifyingglass")
                    }
                    .disabled(tagEditorViewModel.musicSelectedDraft.musicTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || tagEditorViewModel.musicSelectedDraft.artist.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || tagEditorViewModel.isSearchingDiscogs)
                }
                .sheet(isPresented: $showDiscogsResults) {
                    DiscogsAlbumsSheet(tagEditorViewModel: tagEditorViewModel) { album, track in
                        Task {
                            let coverURL = await tagEditorViewModel.applyDiscogsMetadata(album: album, track: track)
                            await MainActor.run {
                                if let coverURL {
                                    pathCoverImage = coverURL.absoluteString
                                    coverImage = NSImage(contentsOf: coverURL) ?? NSImage()
                                } else {
                                    pathCoverImage = ""
                                    reloadCoverImage()
                                }
                                showDiscogsResults = false
                            }
                        }
                    }
                }
                
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
                    ).formattedText(self.tagEditorViewModel.selectedCaseTag),
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
                    ).formattedText(self.tagEditorViewModel.selectedCaseTag),
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
                
                Image(nsImage: coverImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 300, alignment: .bottom)
                    .border(.black)
                    .id("\(tagEditorViewModel.musicSelectedDraft.id)-\(tagEditorViewModel.coverRevision)")
                
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
                            pathCoverImage = ""
                            reloadCoverImage()
                        }
                        finishSaveTag = true
                    }
                    .padding()
                    .disabled(!(self.tagEditorViewModel.musicSelectedDraft != self.tagEditorViewModel.musicSelected || self.tagEditorViewModel.musicLyricDraft != self.tagEditorViewModel.musicLyric || !pathCoverImage.isEmpty))
                    .alert(successSaveTag ? "Novas informações no arquivo de música salvas com sucesso." : "Falha ao salvar novas informações no arquivo de música.", isPresented: $finishSaveTag) {
                        Button(LocalizedStringKey("text_ok"), role: .cancel) { }
                    }
                    
                    Button("Desfazer", role: .cancel) {
                        self.tagEditorViewModel.musicSelectedDraft = self.tagEditorViewModel.musicSelected
                        self.tagEditorViewModel.musicLyricDraft = self.tagEditorViewModel.musicLyric
                        pathCoverImage = ""
                    }
                    .padding()
                    .disabled(!(self.tagEditorViewModel.musicSelectedDraft != self.tagEditorViewModel.musicSelected || self.tagEditorViewModel.musicLyricDraft != self.tagEditorViewModel.musicLyric || !pathCoverImage.isEmpty))
                    Spacer()
                }
                
            }
        }
        .onAppear {
            reloadCoverImage()
        }
        .onChange(of: tagEditorViewModel.musicSelectedDraft.id) { _, _ in
            pathCoverImage = ""
            reloadCoverImage()
        }
        .onChange(of: tagEditorViewModel.coverRevision) { _, _ in
            if pathCoverImage.isEmpty {
                reloadCoverImage()
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
                self.coverImage = NSImage(contentsOf: url) ?? NSImage()
            }
        } else {
            return
        }
        return
    }

    private func reloadCoverImage() {
        coverImage = Id3TagUtils.getImageCover(path: tagEditorViewModel.musicSelectedDraft.filePath) ?? NSImage()
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

struct DiscogsAlbumsSheet: View {
    @ObservedObject var tagEditorViewModel: TagEditorViewModel
    let onSelect: (DiscogsAlbumResult, DiscogsAlbumTrack) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Álbuns encontrados no Discogs")
                    .font(.title3)
                    .bold()
                Spacer()
                if tagEditorViewModel.isSearchingDiscogs {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if let errorMessage = tagEditorViewModel.discogsErrorMessage {
                Text(errorMessage)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else if tagEditorViewModel.isSearchingDiscogs && tagEditorViewModel.discogsAlbums.isEmpty {
                ProgressView("Buscando álbuns...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(tagEditorViewModel.discogsAlbums) { album in
                            HStack(alignment: .top, spacing: 12) {
                                DiscogsCoverThumbnail(url: album.coverURL)

                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(alignment: .firstTextBaseline) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(album.title)
                                                .font(.headline)
                                            Text(album.artist)
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Text(album.year.map(String.init) ?? "Ano desconhecido")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }

                                    if album.tracks.isEmpty {
                                        Text("Sem faixas disponíveis para este álbum.")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    } else {
                                        VStack(alignment: .leading, spacing: 4) {
                                            ForEach(album.tracks) { track in
                                                HStack(spacing: 8) {
                                                    Text(track.position)
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                        .monospacedDigit()
                                                        .frame(width: 44, alignment: .leading)
                                                    Text(track.title)
                                                        .lineLimit(1)
                                                    Spacer()
                                                    if !track.duration.isEmpty {
                                                        Text(track.duration)
                                                            .font(.caption)
                                                            .foregroundStyle(.secondary)
                                                            .monospacedDigit()
                                                    }
                                                    Button {
                                                        onSelect(album, track)
                                                    } label: {
                                                        Label("Usar", systemImage: "checkmark.circle")
                                                    }
                                                    .buttonStyle(.borderless)
                                                }
                                            }
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(10)
                            .background(Color(NSColor.controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
            }
        }
        .padding()
        .frame(minWidth: 650, minHeight: 460)
    }
}

struct DiscogsCoverThumbnail: View {
    let url: URL?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(NSColor.windowBackgroundColor))

            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .controlSize(.small)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    @unknown default:
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 86, height: 86)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

struct FileView: View {
    @ObservedObject var tagEditorViewModel: TagEditorViewModel

    @AppStorage("FileNameMask") private var fileNameMask = "{track:02} - {artist} - {title}"
    @State private var didRenameFile = false
    @State private var showRenameResult = false
    @State private var selectedLibraryPath = ""

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
            Text("Capitalização: **\(tagEditorViewModel.selectedCaseFileName.description)**")
                .font(.subheadline)
                .padding(.bottom, 10)
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
                Spacer()
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

struct ExportView: View {
    @ObservedObject var tagEditorViewModel: TagEditorViewModel

    @State private var selectedLibraryPath = ""
    @State private var deleteOriginal = false
    @State private var exportResult: MusicExportResult = .failed
    @State private var showExportResult = false

    private var exportMessage: String {
        switch exportResult {
        case .exported:
            return "Arquivo exportado para a biblioteca."
        case .exportedAndRemovedOriginal:
            return "Arquivo exportado e original excluído com sucesso."
        case .exportedButCouldNotRemoveOriginal:
            return "Arquivo exportado, mas não foi possível excluir o original."
        case .alreadyExists:
            return "O arquivo já existe na biblioteca selecionada."
        case .failed:
            return "Não foi possível exportar o arquivo."
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

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

            Toggle("Excluir arquivo original após exportar", isOn: $deleteOriginal)
                .disabled(tagEditorViewModel.origin != .fileDir)

            HStack {
                Spacer()
                Button {
                    Task {
                        exportResult = await tagEditorViewModel.exportSelectedMusic(
                            to: selectedLibraryPath,
                            deleteOriginal: deleteOriginal
                        )
                        showExportResult = true
                    }
                } label: {
                    Label("Exportar arquivo", systemImage: "square.and.arrow.up")
                }
                .disabled(selectedLibraryPath.isEmpty || tagEditorViewModel.musicSelected.filePath.isEmpty)
                .alert(exportMessage, isPresented: $showExportResult) {
                    Button(LocalizedStringKey("text_ok"), role: .cancel) { }
                }
                Spacer()
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
}
