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
    private var database: OpaquePointer?
    
    init() {
        print("Path banco de dados (Music Server): \(DBConstants.databasePath)")
        if sqlite3_open_v2(DBConstants.databasePath, &database, SQLITE_OPEN_CREATE|SQLITE_OPEN_READWRITE|SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK {
        } else {
        }
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
            getMusicById(id: Int(param) ?? 0, completion: { path in
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
            getMusicById(id: Int(param) ?? 0, completion: { path in
                if let path = (path! as NSString).removingPercentEncoding?.replacingOccurrences(of: "file://", with: "") {
                    let url = URL(fileURLWithPath: path)
                    if FileManager.default.fileExists(atPath: url.path) {
                        let id3TagEditor: ID3TagEditor = ID3TagEditor()
                        do {
                            let id3Tag = try id3TagEditor.read(from: url.path)
                            if let coverImage = id3Tag?.frames[.attachedPicture(.frontCover)] as? ID3FrameAttachedPicture {
                                self.logs.insert(ServerLog(dateTime: Date.now,
                                                           type: .info,
                                                           descr: "Enviada capa do album."), at: 0)
                                result = GCDWebServerDataResponse(data: coverImage.picture, contentType: "image/jpeg")
                            } else {
                                self.logs.insert(ServerLog(dateTime: Date.now,
                                                           type: .error,
                                                           descr: "Falha ao obter capa do álbum do arquivo \"\(url.lastPathComponent)\"!"), at: 0)
                                result = GCDWebServerDataResponse(html: "<html><body><p>ERRO: FALHA AO LER ARQUIVO</p></body></html>")!
                            }
                        } catch {
                            self.logs.insert(ServerLog(dateTime: Date.now,
                                                       type: .error,
                                                       descr: "Falha ler arquivo \"\(url.lastPathComponent)\"!"), at: 0)
                            print(error)
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
    
    private func getLyric(arrayParam: [String.SubSequence]) -> GCDWebServerDataResponse {
        var result = GCDWebServerDataResponse()
        if arrayParam.count > 1 {
            let param = arrayParam[1]
            getMusicById(id: Int(param) ?? 0, completion: { path in
                if let path = (path! as NSString).removingPercentEncoding?.replacingOccurrences(of: "file://", with: "") {
                    let url = URL(fileURLWithPath: path)
                    if FileManager.default.fileExists(atPath: url.path) {
                        let id3TagEditor: ID3TagEditor = ID3TagEditor()
                        do {
                            let id3Tag = try id3TagEditor.read(from: url.path)
                            if let frame = id3Tag?.frames[.unsynchronizedLyrics(.unknown)] {
                                if let textString = (frame as? ID3FrameWithStringContent)?.content {
                                    self.logs.insert(ServerLog(dateTime: Date.now,
                                                               type: .info,
                                                               descr: "Enviada letra da música."), at: 0)
                                    result = GCDWebServerDataResponse(data: textString.data(using: .utf8) ?? Data(), contentType: "text/plain")
                                } else {
                                    self.logs.insert(ServerLog(dateTime: Date.now,
                                                               type: .error,
                                                               descr: "Falha ao obter a letra da música do arquivo\"\(url.lastPathComponent)\"!"), at: 0)
                                    result = GCDWebServerDataResponse(html: "<html><body><p>ERRO: FALHA AO LER ARQUIVO</p></body></html>")!
                                }
                            } else {
                                self.logs.insert(ServerLog(dateTime: Date.now,
                                                           type: .error,
                                                           descr: "Falha ao obter a letra da música do arquivo\"\(url.lastPathComponent)\"!"), at: 0)
                                result = GCDWebServerDataResponse(html: "<html><body><p>ERRO: FALHA AO LER ARQUIVO</p></body></html>")!
                            }
                        } catch {
                            self.logs.insert(ServerLog(dateTime: Date.now,
                                                       type: .error,
                                                       descr: "Falha ler arquivo \"\(url.lastPathComponent)\"!"), at: 0)
                            print(error)
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
           \(DBConstants.TableMusic.tableName).\(DBConstants.TableMusic.colRowId),
           \(DBConstants.TableArtist.colArtist),
           \(DBConstants.TableMusic.colTitle),
           \(DBConstants.TableMusic.colTrack),
           \(DBConstants.TableMusic.colDuration),
           \(DBConstants.TableAlbum.colAlbum),
           \(DBConstants.TableGenre.colGenre),
           \(DBConstants.TableAlbum.colYear),
           \(DBConstants.TableMusic.colHasLyrics)
        FROM
           \(DBConstants.TableMusic.tableName)
           INNER JOIN \(DBConstants.TableArtist.tableName) ON \(DBConstants.TableArtist.tableName).\(DBConstants.TableArtist.colRowId) = \(DBConstants.TableMusic.colIdArtist)
           INNER JOIN \(DBConstants.TableAlbum.tableName) ON \(DBConstants.TableAlbum.tableName).\(DBConstants.TableAlbum.colRowId) = \(DBConstants.TableMusic.colIdAlbum)
           INNER JOIN \(DBConstants.TableGenre.tableName) ON \(DBConstants.TableGenre.tableName).\(DBConstants.TableGenre.colRowId) = \(DBConstants.TableMusic.colIdGenre)
        ORDER BY
           \(DBConstants.TableMusic.colTitle),
           \(DBConstants.TableArtist.colArtist)
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
                let year = String(cString: sqlite3_column_text(queryStatement, 7))
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
           \(DBConstants.TableMusic.colFilePath)
        FROM
           \(DBConstants.TableMusic.tableName)
        WHERE
           \(DBConstants.TableMusic.colRowId) = \(id)
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
    
    
}
