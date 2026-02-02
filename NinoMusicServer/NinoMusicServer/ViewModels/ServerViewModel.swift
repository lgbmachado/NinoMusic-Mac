//
//  ServerViewModel.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 12/03/25.
//

import Foundation
import GCDWebServer
import ID3TagEditor
import SwiftData
import AppKit

enum ServerComand: String {
    case playMusic = "playMusic"
    case listMusic = "listMusic"
    case getCover = "getCover"
    case getLyric = "getLyric"
    case serverInfo = "serverInfo"
}

class ServerViewModel: ObservableObject {
    @Published var logs: [ServerLog] = []
    
    private let webServer = GCDWebServer()
    private let serverPort:UInt = 8080
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        print("ServerViewModel inicializado com SwiftData")
    }
    
    func startMusicServer() {
        webServer.addDefaultHandler(forMethod: "GET", request: GCDWebServerRequest.self, processBlock: {request in
            let arrayParam = request.path.split(separator: "/")
            let command = String(arrayParam.first ?? "")
            switch ServerComand(rawValue: command) {
            case .playMusic:
                return self.playMusic(arrayParam: arrayParam)
            case .listMusic:
                return self.listMusic()
            case .getCover:
                return self.getCover(arrayParam: arrayParam)
            case .getLyric:
                return self.getLyric(arrayParam: arrayParam)
            case .serverInfo:
                return self.getServerInfo()
                
            default:
                break
            }
            self.logs.insert(ServerLog(dateTime: Date.now,
                                       type: .error,
                                       descr: "Solicitado comando inválido!"), at: 0)
            return GCDWebServerDataResponse(html: "<html><body><p>ERRO: COMANDO INVÁLIDO: \"\(request.path)\"</p></body></html>")!
        })
        self.logs.insert(ServerLog(dateTime: Date.now,
                                   type: .info,
                                   descr: "Servidor inicializado com sucesso!"), at: 0)
        webServer.start(withPort: serverPort, bonjourName: "Nino Music Server")
    }
    
    func stopServer() {
        self.webServer.stop()
        self.logs.insert(ServerLog(dateTime: Date.now,
                                   type: .info,
                                   descr: "Servidor finalizado com sucesso!"), at: 0)
    }
    
    private func playMusic(arrayParam: [String.SubSequence]) -> GCDWebServerDataResponse {
        var result = GCDWebServerDataResponse()
        if arrayParam.count > 1 {
            let param = arrayParam[1]
            getMusicById(seq: Int(param) ?? 0, completion: { path in
                if let path = (path! as NSString).removingPercentEncoding?.replacingOccurrences(of: "file://", with: "") {
                    let url = URL(fileURLWithPath: path)
                    if FileManager.default.fileExists(atPath: url.path) {
                        if let handler = FileHandle.init(forReadingAtPath: url.path) {
                            self.logs.insert(ServerLog(dateTime: Date.now,
                                                       type: .info,
                                                       descr: "Enviado música do arquivo \"\(url.lastPathComponent)\"!"), at: 0)
                            result = GCDWebServerDataResponse(data: (handler.readDataToEndOfFile()), contentType: "audio/mpeg")
                        } else {
                            self.logs.insert(ServerLog(dateTime: Date.now,
                                                       type: .error,
                                                       descr: "Falha ao ler arquivo \"\(url.lastPathComponent)\"!"), at: 0)
                            result = GCDWebServerDataResponse(html: "<html><body><p>ERRO: FALHA AO LER ARQUIVO</p></body></html>")!
                        }
                    } else {
                        self.logs.insert(ServerLog(dateTime: Date.now,
                                                   type: .error,
                                                   descr: "Arquivo \"\(url.lastPathComponent)\" não encontrado!"), at: 0)
                        result = GCDWebServerDataResponse(html: "<html><body><p>ERRO: ARQUIVO NÃO ENCONTRADO</p></body></html>")!
                    }
                }
            })
        } else {
            self.logs.insert(ServerLog(dateTime: Date.now,
                                       type: .error,
                                       descr: "Solicitação sem parâmero!"), at: 0)
            result = GCDWebServerDataResponse(html: "<html><body><p>ERRO: FALTA PARÂMETRO</p></body></html>")!
        }
        return result
    }
    
    private func listMusic() -> GCDWebServerDataResponse {
        var data = Data()
        listMusicsRemote { musicsList in
            if let musicsList = musicsList {
                do {
                    data = try JSONEncoder().encode(musicsList)
                } catch {
                    print(error)
                }
            }
        }
        self.logs.insert(ServerLog(dateTime: Date.now,
                                   type: .info,
                                   descr: "Enviada lista de músicas."), at: 0)
        return GCDWebServerDataResponse(data: data, contentType: "application/json")
    }
    
    private func getCover(arrayParam: [String.SubSequence]) -> GCDWebServerDataResponse {
        var result = GCDWebServerDataResponse()
        if arrayParam.count > 1 {
            let param = arrayParam[1]
            getMusicById(seq: Int(param) ?? 0, completion: { path in
                if let path = (path! as NSString).removingPercentEncoding?.replacingOccurrences(of: "file://", with: "") {
                    let url = URL(fileURLWithPath: path)
                    if FileManager.default.fileExists(atPath: url.path) {
                        if let coverImage = Id3TagUtils.getImageCover(path: url.path),
                           let cgImage = coverImage.cgImage(forProposedRect: nil, context: nil, hints: nil),
                           let jpegData = NSBitmapImageRep(cgImage: cgImage).representation(using: NSBitmapImageRep.FileType.jpeg, properties: [:]) {
                            self.logs.insert(ServerLog(dateTime: Date.now,
                                                       type: .info,
                                                       descr: "Enviada capa do album."), at: 0)
                            result = GCDWebServerDataResponse(data: jpegData, contentType: "image/jpeg")
                        }
                        self.logs.insert(ServerLog(dateTime: Date.now,
                                                   type: .error,
                                                   descr: "Falha ao obter capa do álbum do arquivo \"\(url.lastPathComponent)\"!"), at: 0)
                    } else {
                        self.logs.insert(ServerLog(dateTime: Date.now,
                                                   type: .error,
                                                   descr: "Arquivo \"\(url.lastPathComponent)\" não encontrado!"), at: 0)
                        result = GCDWebServerDataResponse(html: "<html><body><p>ERRO: ARQUIVO NÃO ENCONTRADO</p></body></html>")!
                    }
                }
            })
        } else {
            self.logs.insert(ServerLog(dateTime: Date.now,
                                       type: .error,
                                       descr: "Solicitação sem parâmetro!"), at: 0)
            result = GCDWebServerDataResponse(html: "<html><body><p>ERRO: FALTA PARÂMETRO</p></body></html>")!
        }
        return result
}
    
    private func getLyric(arrayParam: [String.SubSequence]) -> GCDWebServerDataResponse {
        var result = GCDWebServerDataResponse()
        if arrayParam.count > 1 {
            let param = arrayParam[1]
            getMusicById(seq: Int(param) ?? 0, completion: { path in
                if let path = (path! as NSString).removingPercentEncoding?.replacingOccurrences(of: "file://", with: "") {
                    let url = URL(fileURLWithPath: path)
                    if FileManager.default.fileExists(atPath: url.path) {
                        if let lyricString = Id3TagUtils.getLyrics(path: url.path) {
                            self.logs.insert(ServerLog(dateTime: Date.now,
                                                       type: .info,
                                                       descr: "Enviada letra da música."), at: 0)
                            result = GCDWebServerDataResponse(data: lyricString.data(using: .utf8) ?? Data(), contentType: "text/plain")
                        } else {
                            self.logs.insert(ServerLog(dateTime: Date.now,
                                                       type: .error,
                                                       descr: "Falha ao obter a letra da música do arquivo\"\(url.lastPathComponent)\"!"), at: 0)
                            result = GCDWebServerDataResponse(html: "<html><body><p>ERRO: FALHA AO LER ARQUIVO</p></body></html>")!
                        }

                    } else {
                        self.logs.insert(ServerLog(dateTime: Date.now,
                                                   type: .error,
                                                   descr: "Arquivo \"\(url.lastPathComponent)\" não encontrado!"), at: 0)
                        result = GCDWebServerDataResponse(html: "<html><body><p>ERRO: ARQUIVO NÃO ENCONTRADO</p></body></html>")!
                    }
                }
            })
        } else {
            self.logs.insert(ServerLog(dateTime: Date.now,
                                       type: .error,
                                       descr: "Solicitação sem parâmetro!"), at: 0)
            result = GCDWebServerDataResponse(html: "<html><body><p>ERRO: FALTA PARÂMETRO</p></body></html>")!
        }
        return result
    }
    
    private func getServerInfo() -> GCDWebServerDataResponse {
        var data = Data()
        let defaults = UserDefaults.standard
        let serverName = defaults.string(forKey: "ServerName")
        let musicCount = defaults.integer(forKey: "MusicsCount")
        let lastUpdate = defaults.string(forKey: "LastUpdate")
        
        let serverInfo = ServerInfo(server_name: serverName, music_count: musicCount, last_update: lastUpdate)
        
        do {
            data = try JSONEncoder().encode(serverInfo)
        } catch {
            print(error)
        }
        self.logs.insert(ServerLog(dateTime: Date.now,
                                   type: .info,
                                   descr: "Enviada dados do servidor."), at: 0)
        return GCDWebServerDataResponse(data: data, contentType: "application/json")
    }
    
    func listMusicsRemote(completion: @escaping ([Music]?) -> ()) {
        let descriptor = FetchDescriptor<Music>(
            sortBy: [
                SortDescriptor(\Music.musicTitle),
                SortDescriptor(\Music.artist)
            ]
        )
        
        do {
            var musicListRemote = try modelContext.fetch(descriptor)
            
            // Adicionar sequência às músicas
            for (index, music) in musicListRemote.enumerated() {
                music.seq = index + 1
            }
            
            completion(musicListRemote)
        } catch {
            print("Erro ao buscar músicas: \(error)")
            completion(nil)
        }
    }
    
    func getMusicById(seq: Int, completion: @escaping (String?) -> ()) {
        let descriptor = FetchDescriptor<Music>(
            predicate: #Predicate { $0.seq == seq }
        )
        
        do {
            let musics = try modelContext.fetch(descriptor)
            if let music = musics.first {
                completion(music.filePath)
            } else {
                completion(nil)
            }
        } catch {
            print("Erro ao buscar música por ID: \(error)")
            completion(nil)
        }
    }
    
}
