//
//  ConfigurationsView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Baptista Machado on 27/03/26.
//

import Foundation
import SwiftUI
import ID3TagEditor

struct ConfigurationsView: View {
    @ObservedObject var tagEditorViewModel: TagEditorViewModel
    @ObservedObject var serverViewModel: ServerViewModel
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()
            HStack(spacing: 10) {
                Image(nsImage: NSImage(named: "NinoMusic") ?? NSImage(named: NSImage.applicationIconName)!)
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                Text("Configurações")
                    .font(.title)
                    .fontWeight(.semibold)
            }
            
            Divider()
            
            TabView {
                TagEditorConfig(tagEditorViewModel: tagEditorViewModel)
                    .tabItem {
                        Image(systemName: "")
                        Text("Edição de Tags")
                    }
                ServerConfig(serverViewModel: serverViewModel)
                    .tabItem {
                        Image(systemName: "")
                        Text("Servidor de Músicas")
                    }
            }
            
            HStack {
                Spacer()
                Button("Salvar Configurações") {
                    dismiss()
                }
                .padding()
                
                Button("Cancelar", role: .cancel) {
                    dismiss()
                }
                .padding()
                Spacer()
            }
        }
        .padding(28)
        .frame(width: 600, height: 700)
    }
    
}

struct TagEditorConfig: View {
    @ObservedObject var tagEditorViewModel: TagEditorViewModel
    
    @State private var inputText: String = ""
    @State private var selectedGenres: [String] = [String]()
    
    var body: some View {
        VStack(alignment: .leading) {
            GroupBox("Capitalização:") {
                VStack(alignment: .leading, spacing: 8) {
                    ComboBox(
                        text: Binding(
                            get: {
                                tagEditorViewModel.selectedCase.description
                            },
                            set: {
                                tagEditorViewModel.selectedCase = CaseKind(rawValue: $0) ?? .uppercase
                            }
                        ),
                        items: CaseKind.allDescriptions,
                        placeholder: "Capitalização:"
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Spacer()
            
            GroupBox("Gêneros:") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Gêneros selecionados:")
                        .font(.headline)
                    
                    WrapView(items: selectedGenres) { item in
                        HStack(spacing: 6) {
                            Text(item)
                            Button("✕") {
                                selectedGenres.removeAll { $0 == item }
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.18))
                        .clipShape(Capsule())
                    }
                    
                    Spacer()
                    
                    Text("Adicionar gêneros:")
                        .font(.headline)
                    
                    TextField("Digite um gênero customizado...", text: $inputText)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            addItem(inputText)
                        }
                    
                    Text("Gêneros prédefinidos:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(Id3TagUtils.genresAvaiables(), id: \.self) { item in
                                Button {
                                    addItem(item)
                                } label: {
                                    HStack(spacing: 8) {
                                        Text("•")
                                        Text(item)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 2)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 110)
                    .padding(.vertical, 2)
                    
                    Divider()
                    
                }
            }
        }
        .frame(width: 500, height: 500, alignment: .top)
        .onAppear {
            self.selectedGenres = tagEditorViewModel.genresAvaiables
        }
    }
    
    private func addItem(_ item: String) {
        let trimmed = item.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        guard !selectedGenres.contains(trimmed) else { return }
        
        self.selectedGenres.append(trimmed)
        tagEditorViewModel.genresAvaiables = self.selectedGenres
        inputText = ""
    }
    
}

struct ServerConfig: View {
    @ObservedObject var serverViewModel: ServerViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Porta do servidor de músicas:")
                .font(.caption2)
                .padding(.bottom, -7)
            TextField(
                "Porta do servidor",
                text: Binding(
                    get: { String(serverViewModel.serverPort) },
                    set: { serverViewModel.updateServerPort($0) }
                )
            )
            Spacer()
        }
        .frame(width: 500, height: 500, alignment: .top)
    }
}
