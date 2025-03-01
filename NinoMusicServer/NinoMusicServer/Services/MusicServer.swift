//
//  MusicServer.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 04/10/23.
//

import Foundation
import GCDWebServer
import ID3TagEditor

enum ServerComand: String {
    case playMusic = "playMusic"
    case listMusic = "listMusic"
    case getCover = "getCover"
    case serverInfo = "serverInfo"
}

class MusicServer {
    private let webServer = GCDWebServer()
    
    func start() {
        webServer.addDefaultHandler(forMethod: "GET", request: GCDWebServerRequest.self, processBlock: {request in
            let arrayParam = request.path.split(separator: "/")
            let command = String(arrayParam.first ?? "")
            var result = GCDWebServerDataResponse()
            switch ServerComand(rawValue: command) {
            case .playMusic:
                if arrayParam.count > 1 {
                    let param = arrayParam[1]
                    let musicDb = Database()
                    musicDb.getMusicById(id: Int(param) ?? 0, completion: { path in
                        if let path = (path! as NSString).removingPercentEncoding?.replacingOccurrences(of: "file://", with: "") {
                            let url = URL(fileURLWithPath: path)
                            if FileManager.default.fileExists(atPath: url.path) {
                                if let handler = FileHandle.init(forReadingAtPath: url.path) {
                                    result = GCDWebServerDataResponse(data: (handler.readDataToEndOfFile()), contentType: "audio/mpeg")
                                } else {
                                    result = GCDWebServerDataResponse(html: "<html><body><p>ERRO: FALHA AO LER ARQUIVO</p></body></html>")!
                                }
                            } else {
                                result = GCDWebServerDataResponse(html: "<html><body><p>ERRO: ARQUIVO NÃO ENCONTRADO</p></body></html>")!
                            }
                        }
                    })
                } else {
                    result = GCDWebServerDataResponse(html: "<html><body><p>ERRO: FALTA PARÂMETRO</p></body></html>")!
                }
                return result
            case .listMusic:
                var data = Data()
                let musicDb = Database()
                musicDb.listMusicsRemote { musicsList in
                    if let musicsList = musicsList {
                        do {
                            data = try JSONEncoder().encode(musicsList)
                        } catch {
                            print(error)
                        }
                    }
                }
                musicDb.closeDatabase()
                return GCDWebServerDataResponse(data: data, contentType: "application/json")
            case .getCover:
                if arrayParam.count > 1 {
                    let param = arrayParam[1]
                    let musicDb = Database()
                    musicDb.getMusicById(id: Int(param) ?? 0, completion: { path in
                        if let path = (path! as NSString).removingPercentEncoding?.replacingOccurrences(of: "file://", with: "") {
                            let url = URL(fileURLWithPath: path)
                            if FileManager.default.fileExists(atPath: url.path) {
                                let id3TagEditor: ID3TagEditor = ID3TagEditor()
                                do {
                                    let id3Tag = try id3TagEditor.read(from: url.path)
                                    if let coverImage = id3Tag?.frames[.attachedPicture(.frontCover)] as? ID3FrameAttachedPicture {
                                        result = GCDWebServerDataResponse(data: coverImage.picture, contentType: "image/jpeg")
                                    } else {
                                        result = GCDWebServerDataResponse(html: "<html><body><p>ERRO: FALHA AO LER ARQUIVO</p></body></html>")!
                                    }
                                } catch {
                                    print(error)
                                }
                            } else {
                                result = GCDWebServerDataResponse(html: "<html><body><p>ERRO: ARQUIVO NÃO ENCONTRADO</p></body></html>")!
                            }
                        }
                    })
                } else {
                    result = GCDWebServerDataResponse(html: "<html><body><p>ERRO: FALTA PARÂMETRO</p></body></html>")!
                }
                return result
            case .serverInfo:
                var data = Data()
                
                let defaults = UserDefaults.standard
                let serverName = defaults.string(forKey: "ServerName")
                let musicCount = defaults.string(forKey: "MusicsCount")
                let lastUpdate = defaults.string(forKey: "LastUpdate")
                
                let serverInfo = ServerInfoRemote(server_name: serverName, music_count: musicCount, last_update: lastUpdate)
                
                do {
                    data = try JSONEncoder().encode(serverInfo)
                } catch {
                    print(error)
                }
                
                return GCDWebServerDataResponse(data: data, contentType: "application/json")
            default:
                break
            }
            return GCDWebServerDataResponse(html: "<html><body><p>ERRO: COMANDO INVÁLIDO: \"\(request.path)\"</p></body></html>")!
        })
        webServer.start(withPort: 8080, bonjourName: "Nino Music Server")
    }
}
