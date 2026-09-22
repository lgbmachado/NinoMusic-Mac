//
//  ServerViewModel.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 12/03/25.
//

import Foundation
import GCDWebServer
import ID3TagEditor
import SQLite3
import AppKit

enum ServerComand: String {
    case playMusic = "playMusic"
    case listMusic = "listMusic"
    case getCover = "getCover"
    case getLyric = "getLyric"
    case serverInfo = "serverInfo"
}

enum MusicSharingProtocol: String, CaseIterable, Identifiable {
    case http = "HTTP Stream"
    case upnp = "UPnP"

    var id: Self { self }
}

class ServerViewModel: ObservableObject {
    @Published var logs: [ServerLog] = []
    @Published var serverPort: UInt = 8080
    @Published var sharingProtocol: MusicSharingProtocol = .http
    @Published private(set) var isRunning = false
    
    private let webServer = GCDWebServer()
    private let ssdpService = SSDPService()
    private let upnpMediaServer: UPnPMediaServer
    private var database: OpaquePointer?
    
    init() {
        let defaults = UserDefaults.standard
        let storedUUID = defaults.string(forKey: "UPnPDeviceUUID") ?? UUID().uuidString
        defaults.set(storedUUID, forKey: "UPnPDeviceUUID")
        upnpMediaServer = UPnPMediaServer(deviceUUID: storedUUID)

        print("Path banco de dados (Music Server): \(DbConstants.databasePath)")
        if sqlite3_open_v2(DbConstants.databasePath, &database, SQLITE_OPEN_CREATE|SQLITE_OPEN_READWRITE|SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK {
        } else {
        }
        configureHandlers()
    }
    
    func startMusicServer() {
        guard !isRunning else { return }
        let started = webServer.start(withPort: serverPort, bonjourName: "Nino Music Server")
        guard started else {
            logs.insert(ServerLog(dateTime: Date.now,
                                  type: .error,
                                  descr: "Falha ao iniciar o servidor na porta \(serverPort)."), at: 0)
            return
        }

        if sharingProtocol == .upnp {
            guard let localAddress = SSDPService.localIPv4Address() else {
                webServer.stop()
                logs.insert(ServerLog(dateTime: Date.now,
                                      type: .error,
                                      descr: "Não foi possível identificar o endereço da rede local."), at: 0)
                return
            }
            do {
                try ssdpService.start(location: "http://\(localAddress):\(serverPort)/upnp/device.xml",
                                      uuid: upnpMediaServer.deviceUUID)
            } catch {
                webServer.stop()
                logs.insert(ServerLog(dateTime: Date.now,
                                      type: .error,
                                      descr: "Falha ao publicar o servidor UPnP: \(error.localizedDescription)"), at: 0)
                return
            }
        }

        isRunning = true
        logs.insert(ServerLog(dateTime: Date.now,
                              type: .info,
                              descr: "Servidor \(sharingProtocol.rawValue) inicializado com sucesso!"), at: 0)
    }

    private func configureHandlers() {
        webServer.addDefaultHandler(forMethod: "GET", request: GCDWebServerRequest.self, processBlock: {request in
            if request.path.hasPrefix("/upnp/") {
                return self.upnpGetResponse(path: request.path)
            }
            let arrayParam = request.path.split(separator: "/")
            let command = String(arrayParam.first ?? "")
            switch ServerComand(rawValue: command) {
            case .playMusic:
                return self.playMusic(arrayParam: arrayParam, request: request)
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
        webServer.addDefaultHandler(forMethod: "POST", request: GCDWebServerDataRequest.self, processBlock: { request in
            guard let dataRequest = request as? GCDWebServerDataRequest else {
                return self.response(statusCode: 400)
            }
            return self.upnpPostResponse(path: dataRequest.path, data: dataRequest.data)
        })
    }
    
    func stopServer() {
        ssdpService.stop()
        self.webServer.stop()
        isRunning = false
        self.logs.insert(ServerLog(dateTime: Date.now,
                                   type: .info,
                                   descr: "Servidor finalizado com sucesso!"), at: 0)
    }
    
    private func playMusic(arrayParam: [String.SubSequence], request: GCDWebServerRequest) -> GCDWebServerResponse {
        var result: GCDWebServerResponse = response(statusCode: 404)
        if arrayParam.count > 1 {
            let param = arrayParam[1]
            getMusicById(id: Int(param) ?? 0, completion: { path in
                if let path = (path! as NSString).removingPercentEncoding?.replacingOccurrences(of: "file://", with: "") {
                    let url = URL(fileURLWithPath: path)
                    if FileManager.default.fileExists(atPath: url.path) {
                        self.logs.insert(ServerLog(dateTime: Date.now,
                                                   type: .info,
                                                   descr: "Enviada música do arquivo \"\(url.lastPathComponent)\"!"), at: 0)
                        result = GCDWebServerFileResponse(file: url.path, byteRange: request.byteRange) ?? self.response(statusCode: 404)
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
        var result = response(statusCode: 404)
        if arrayParam.count > 1 {
            let param = arrayParam[1]
            getMusicById(id: Int(param) ?? 0, completion: { path in
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
                            return
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

    private func upnpGetResponse(path: String) -> GCDWebServerResponse {
        guard sharingProtocol == .upnp, isRunning else { return response(statusCode: 404) }
        let serverName = UserDefaults.standard.string(forKey: "ServerName") ?? "Nino Music Server"
        let localAddress = SSDPService.localIPv4Address() ?? "127.0.0.1"
        let baseURL = "http://\(localAddress):\(serverPort)"
        let xml: String
        switch path {
        case "/upnp/device.xml":
            xml = upnpMediaServer.deviceDescription(serverName: serverName, baseURL: baseURL)
        case "/upnp/content-directory.xml":
            xml = upnpMediaServer.contentDirectoryDescription()
        case "/upnp/connection-manager.xml":
            xml = upnpMediaServer.connectionManagerDescription()
        default:
            return response(statusCode: 404)
        }
        return GCDWebServerDataResponse(data: Data(xml.utf8), contentType: "text/xml; charset=\"utf-8\"")
    }

    private func upnpPostResponse(path: String, data: Data) -> GCDWebServerResponse {
        guard sharingProtocol == .upnp, isRunning else { return response(statusCode: 404) }
        let localAddress = SSDPService.localIPv4Address() ?? "127.0.0.1"
        let xml: String
        switch path {
        case "/upnp/control/content-directory":
            var musics: [Music] = []
            listMusicsRemote { musics = $0 ?? [] }
            xml = upnpMediaServer.contentDirectoryResponse(requestData: data,
                                                           musics: musics,
                                                           baseURL: "http://\(localAddress):\(serverPort)")
        case "/upnp/control/connection-manager":
            xml = upnpMediaServer.connectionManagerResponse(requestData: data)
        default:
            return response(statusCode: 404)
        }
        return GCDWebServerDataResponse(data: Data(xml.utf8), contentType: "text/xml; charset=\"utf-8\"")
    }

    private func response(statusCode: Int) -> GCDWebServerDataResponse {
        let result = GCDWebServerDataResponse(data: Data(), contentType: "text/plain")
        result.statusCode = statusCode
        return result
    }
    
    private func getLyric(arrayParam: [String.SubSequence]) -> GCDWebServerDataResponse {
        var result = GCDWebServerDataResponse()
        if arrayParam.count > 1 {
            let param = arrayParam[1]
            getMusicById(id: Int(param) ?? 0, completion: { path in
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
        let sql = """
        SELECT
           \(DbConstants.TableMusic.tableName).\(DbConstants.TableMusic.colMusicId),
           \(DbConstants.TableArtist.colArtist),
           \(DbConstants.TableMusic.colTitle),
           \(DbConstants.TableMusic.colTrack),
           \(DbConstants.TableMusic.colDuration),
           \(DbConstants.TableAlbum.colAlbum),
           \(DbConstants.TableGenre.colGenre),
           \(DbConstants.TableAlbum.colYear),
           \(DbConstants.TableMusic.colHasLyrics)
        FROM
           \(DbConstants.TableMusic.tableName)
           INNER JOIN \(DbConstants.TableArtist.tableName) ON \(DbConstants.TableArtist.tableName).\(DbConstants.TableArtist.colArtistId) = \(DbConstants.TableMusic.colIdArtist)
           INNER JOIN \(DbConstants.TableAlbum.tableName) ON \(DbConstants.TableAlbum.tableName).\(DbConstants.TableAlbum.colAlbumId) = \(DbConstants.TableMusic.colIdAlbum)
           INNER JOIN \(DbConstants.TableGenre.tableName) ON \(DbConstants.TableGenre.tableName).\(DbConstants.TableGenre.colGenreId) = \(DbConstants.TableMusic.colIdGenre)
        ORDER BY
           \(DbConstants.TableMusic.colTitle),
           \(DbConstants.TableArtist.colArtist)
        """
        var queryStatement: OpaquePointer?
        var musicListRemote = [Music]()
        var seq = 0
    
        if sqlite3_prepare_v2(self.database, sql, -1, &queryStatement, nil) == SQLITE_OK {
            while(sqlite3_step(queryStatement) == SQLITE_ROW) {
                seq += 1
                let idServer = Int(sqlite3_column_int(queryStatement, 0))
                let artist = String(cString: sqlite3_column_text(queryStatement, 1))
                let album = String(cString: sqlite3_column_text(queryStatement, 5))
                let year = Int(sqlite3_column_int(queryStatement, 7))
                let track = Int(sqlite3_column_int(queryStatement, 3))
                let musicTitle = String(cString: sqlite3_column_text(queryStatement, 2))
                let genre = String(cString: sqlite3_column_text(queryStatement, 6))
                let duration = Int(sqlite3_column_int(queryStatement, 4))
                let hasLyric = Int(sqlite3_column_int(queryStatement, 8)) == 1
    
                musicListRemote.append(Music(seq: seq,
                                             idServer: idServer,
                                             artist: artist,
                                             album: album,
                                             year: year,
                                             track: track,
                                             musicTitle: musicTitle,
                                             genre: genre,
                                             duration: duration,
                                             filePath: "",
                                             hasLyric: hasLyric))
            }
        }
        sqlite3_finalize(queryStatement)
        completion(musicListRemote)
    }
    
    func getMusicById(id: Int, completion: @escaping (String?) -> ()) {
        let sql = """
        SELECT
           \(DbConstants.TableMusic.colFilePath)
        FROM
           \(DbConstants.TableMusic.tableName)
        WHERE
           \(DbConstants.TableMusic.colMusicId) = \(id)
        """
        var queryStatement: OpaquePointer?
        var result = ""
    
        if sqlite3_prepare_v2(self.database, sql, -1, &queryStatement, nil) == SQLITE_OK {
            while(sqlite3_step(queryStatement) == SQLITE_ROW) {
                result = String(cString: sqlite3_column_text(queryStatement, 0))
            }
        }
        sqlite3_finalize(queryStatement)
        completion(result)
    }
    
    func closeDatabase() {
        if sqlite3_close(self.database) != SQLITE_OK {
            print("error closing database")
        }
    }
    
    func updateServerPort(_ newPort: String) {
        self.serverPort = UInt(newPort) ?? 8080
    }
    
    
}
