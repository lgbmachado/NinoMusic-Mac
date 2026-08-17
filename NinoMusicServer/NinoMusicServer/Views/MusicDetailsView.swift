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
                            set: {_,_ in }
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
                    .frame(width: .infinity, height: .infinity, alignment: .bottom)
                    .scaledToFit()
                    .aspectRatio(contentMode: .fit)
                    .border(.black)
                
                Text("Letra")
                    .font(.caption2)
                    .padding(.bottom, -7)
                TextEditor(text: $tagEditorViewModel.musicLyric)
                    .disabled(false)
                    .font(.body)
                    .padding(4)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
                    .frame(width: .infinity, height: 300, alignment: .bottom)
                            
                
                Spacer()
                HStack {
                    Spacer()
                    Button("Salvar") {
                        successSaveTag = self.tagEditorViewModel.SetMusicTags(coverImagePath: pathCoverImage)
                        finishSaveTag = true
                    }
                    .padding()
                    .disabled(!(self.tagEditorViewModel.musicSelectedDraft != self.tagEditorViewModel.musicSelected))
                    .alert(successSaveTag ? "Novas informações no arquivo de música salvas com suvesso." : "Falha ao salvar novas informações no arquivo de música.", isPresented: $finishSaveTag) {
                        Button(LocalizedStringKey("text_ok"), role: .cancel) { }
                    }
                    
                    Button("Desfazer", role: .cancel) {
                        self.tagEditorViewModel.musicSelectedDraft = self.tagEditorViewModel.musicSelected
                    }
                    .padding()
                    .disabled(!(self.tagEditorViewModel.musicSelectedDraft != self.tagEditorViewModel.musicSelected))
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
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(LocalizedStringKey("text_file"))
                .font(.caption2)
                .padding(.bottom, -7)
            TextField(LocalizedStringKey("text_file_name"), text: $tagEditorViewModel.fileSelected)
            Spacer()
        }
    }
}
