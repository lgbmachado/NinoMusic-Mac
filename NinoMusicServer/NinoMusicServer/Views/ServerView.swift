//
//  ServerView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 05/08/24.
//

import SwiftUI
import GCDWebServer
import ID3TagEditor

enum ServerComand: String {
    case playMusic = "playMusic"
    case listMusic = "listMusic"
    case getCover = "getCover"
    case serverInfo = "serverInfo"
}

struct ServerView: View {
    private let webServer = GCDWebServer()
    private let serverPort:UInt = 8080
    @State var tableData = [ServerLog]()
    @State private var showAlert = false
    
    var body: some View {
        Table(tableData) {
            TableColumn(LocalizedStringKey("text_date_time")) {serverLog in
                Text(DateString(serverLog.dateTime))
            }
            .width(140)
            TableColumn(LocalizedStringKey("text_type")) { serverLog in
                switch serverLog.type {
                case .info:
                    Image(systemName: ServerLogType.info.iconName)
                case .warning:
                    Image(systemName: ServerLogType.warning.iconName)
                case .error:
                    Image(systemName: ServerLogType.error.iconName)
                }
            }
            .width(40)
            .alignment(.center)
            TableColumn(LocalizedStringKey("text_description"), value: \.descr)
        }
        .padding()
        .confirmationDialog(LocalizedStringKey("text_confirm_start_server"), isPresented: $showAlert) {
            Button(LocalizedStringKey("text_yes")) {
                StartMusicServer()
            }
            Button(LocalizedStringKey("text_no"), role: .cancel) {
            }
        }
        .dialogIcon(Image(systemName: "server.rack"))
        .toolbar {
            ToolbarItem(placement: .navigation) {
                HStack {
                    Button("", systemImage: "flag.pattern.checkered.circle", action: {
                        showAlert = true
                    })
                    .font(.system(size: 25))
                    .buttonStyle(.borderless)
                    Button("", systemImage: "stop.circle", action: {
                        tableData.insert(ServerLog(dateTime: Date.now,
                                                   type: .info,
                                                   descr: "Servidor finalizado com sucesso!"), at: 0)
                    })
                    .font(.system(size: 25))
                    .buttonStyle(.borderless)
                }
            }
        }
    }
    
    func DateString(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current.identifier == "pt_BR" ? Locale(identifier: "pt_BR") : Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = Locale.current.identifier == "pt_BR" ? "dd/MM/yyyy HH:mm:ss" : "MM/dd/yyyy HH:mm:ss"
        return dateFormatter.string(from: date)
    }
    
    func StartMusicServer() {
        webServer.addDefaultHandler(forMethod: "GET", request: GCDWebServerRequest.self, processBlock: {request in
            let arrayParam = request.path.split(separator: "/")
            let command = String(arrayParam.first ?? "")
            switch ServerComand(rawValue: command) {
            case .playMusic:
                return PlayMusic(arrayParam: arrayParam)
            case .listMusic:
                return ListMusic()
            case .getCover:
                return GetCover(arrayParam: arrayParam)
            case .serverInfo:
                return ServerInfo()

            default:
                break
            }
            tableData.insert(ServerLog(dateTime: Date.now,
                                       type: .error,
                                       descr: "Solicitado comando inválido!"), at: 0)
            return GCDWebServerDataResponse(html: "<html><body><p>ERRO: COMANDO INVÁLIDO: \"\(request.path)\"</p></body></html>")!
        })
        tableData.insert(ServerLog(dateTime: Date.now,
                                   type: .info,
                                   descr: "Servidor inicializado com sucesso!"), at: 0)
        webServer.start(withPort: serverPort, bonjourName: "Nino Music Server")
    }
    
    func PlayMusic(arrayParam: [String.SubSequence]) -> GCDWebServerDataResponse {
        var result = GCDWebServerDataResponse()
        if arrayParam.count > 1 {
            let param = arrayParam[1]
            let musicDb = Database()
            musicDb.getMusicById(id: Int(param) ?? 0, completion: { path in
                if let path = (path! as NSString).removingPercentEncoding?.replacingOccurrences(of: "file://", with: "") {
                    let url = URL(fileURLWithPath: path)
                    if FileManager.default.fileExists(atPath: url.path) {
                        if let handler = FileHandle.init(forReadingAtPath: url.path) {
                            tableData.insert(ServerLog(dateTime: Date.now,
                                                       type: .info,
                                                       descr: "Enviado música do arquivo \"\(url.lastPathComponent)\"!"), at: 0)
                            result = GCDWebServerDataResponse(data: (handler.readDataToEndOfFile()), contentType: "audio/mpeg")
                        } else {
                            tableData.insert(ServerLog(dateTime: Date.now,
                                                       type: .error,
                                                       descr: "Falha ao ler arquivo \"\(url.lastPathComponent)\"!"), at: 0)
                            result = GCDWebServerDataResponse(html: "<html><body><p>ERRO: FALHA AO LER ARQUIVO</p></body></html>")!
                        }
                    } else {
                        tableData.insert(ServerLog(dateTime: Date.now,
                                                   type: .error,
                                                   descr: "Arquivo \"\(url.lastPathComponent)\" não encontrado!"), at: 0)
                        result = GCDWebServerDataResponse(html: "<html><body><p>ERRO: ARQUIVO NÃO ENCONTRADO</p></body></html>")!
                    }
                }
            })
        } else {
            tableData.insert(ServerLog(dateTime: Date.now,
                                       type: .error,
                                       descr: "Solicitação sem parâmero!"), at: 0)
            result = GCDWebServerDataResponse(html: "<html><body><p>ERRO: FALTA PARÂMETRO</p></body></html>")!
        }
        return result
    }
    
    func ListMusic() -> GCDWebServerDataResponse {
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
        tableData.insert(ServerLog(dateTime: Date.now,
                                   type: .info,
                                   descr: "Enviada lista de músicas."), at: 0)
        return GCDWebServerDataResponse(data: data, contentType: "application/json")
    }
    
    func GetCover(arrayParam: [String.SubSequence]) -> GCDWebServerDataResponse {
        var result = GCDWebServerDataResponse()
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
                                tableData.insert(ServerLog(dateTime: Date.now,
                                                           type: .info,
                                                           descr: "Enviada capa do album."), at: 0)
                                result = GCDWebServerDataResponse(data: coverImage.picture, contentType: "image/jpeg")
                            } else {
                                tableData.insert(ServerLog(dateTime: Date.now,
                                                           type: .error,
                                                           descr: "Falha ao obter capa do álbum do arquivo \"\(url.lastPathComponent)\"!"), at: 0)
                                result = GCDWebServerDataResponse(html: "<html><body><p>ERRO: FALHA AO LER ARQUIVO</p></body></html>")!
                            }
                        } catch {
                            tableData.insert(ServerLog(dateTime: Date.now,
                                                       type: .error,
                                                       descr: "Falha ler arquivo \"\(url.lastPathComponent)\"!"), at: 0)
                            print(error)
                        }
                    } else {
                        tableData.insert(ServerLog(dateTime: Date.now,
                                                   type: .error,
                                                   descr: "Arquivo \"\(url.lastPathComponent)\" não encontrado!"), at: 0)
                        result = GCDWebServerDataResponse(html: "<html><body><p>ERRO: ARQUIVO NÃO ENCONTRADO</p></body></html>")!
                    }
                }
            })
        } else {
            tableData.insert(ServerLog(dateTime: Date.now,
                                       type: .error,
                                       descr: "Solicitação sem parâmetro!"), at: 0)
            result = GCDWebServerDataResponse(html: "<html><body><p>ERRO: FALTA PARÂMETRO</p></body></html>")!
        }
        return result
    }
    
    func ServerInfo() -> GCDWebServerDataResponse {
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
        tableData.insert(ServerLog(dateTime: Date.now,
                                   type: .info,
                                   descr: "Enviada dados do servidor."), at: 0)
        return GCDWebServerDataResponse(data: data, contentType: "application/json")
    }
    
}


#Preview {
    ServerView()
}
