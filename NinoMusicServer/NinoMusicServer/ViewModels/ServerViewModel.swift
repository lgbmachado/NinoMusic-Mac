//
//  ServerViewModel.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 12/03/25.
//
// Gerencia a função de servidor do programa permitindo compartilhar músicas através de uma web-app que pode ser acessado por um navegado qualquer ou através
// do protocolo UPnP que pode ser acessado de um equipamento ou programa compatível (Smart-TV, programas, equipamentos, etc)

import Foundation
import GCDWebServer
import ID3TagEditor
import SQLite3
import AppKit

//Enumerador que indica qual é o comando da Api excutado
enum ServerComand: String {
    case playMusic = "playMusic"
    case listMusic = "listMusic"
    case getCover = "getCover"
    case getLyric = "getLyric"
    case serverInfo = "serverInfo"
}

//Enumerador que indica qual é o protocolo de servidor a ser executado
enum MusicSharingProtocol: String, CaseIterable, Identifiable {
    case http = "App Web"
    case upnp = "UPnP"

    var id: Self { self }
}


class ServerViewModel: ObservableObject {
    @Published var logs: [ServerLog] = []                        // Lista com os logs do servidor de música.
    @Published var serverPort: UInt = 8080                       // Número da porta de rede a ser acessado pelo cliente
    @Published var sharingProtocol: MusicSharingProtocol = .http // Define o protocolo de compartilhamento da música.
    @Published private(set) var isRunning = false                // Flag que indica se o servidor está em execução.
    
    private let webServer = GCDWebServer()                       // Objeto que gerencia o servidor web.
    private let ssdpService = SSDPService()                      // Objeto que gerencia o serviço do protocolo UPnP
    private let upnpMediaServer: UPnPMediaServer
    private let coverResponseCache = NSCache<NSString, NSData>()
    private let coverCacheLock = NSLock()
    private var musicCoverKeys: [Int: String] = [:]
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
    
    /// Inicia o servidor de música.
    ///
    /// Use este método para iniciar o servidor tanto de aplicativo como para aplicativo.
    ///
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
            if request.path == "/" || request.path == "/index.html" {
                return GCDWebServerDataResponse(html: self.webPlayerPage())!
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

    private func webPlayerPage() -> String {
        #"""
        <!doctype html>
        <html lang="pt-BR">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width,initial-scale=1">
          <meta name="theme-color" content="#101114">
          <title>Nino Music</title>
          <style>
            :root{color-scheme:dark;--bg:#101114;--panel:#191a1f;--muted:#9799a3;--text:#f5f5f7;--accent:#c8f36a;--line:#2a2b31}
            *{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--text);font:15px -apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif}
            .shell{max-width:1050px;margin:auto;padding:32px 24px 130px}.top{display:flex;align-items:center;gap:12px;margin-bottom:32px}.mark{width:40px;height:40px;border-radius:13px;background:var(--accent);color:#171910;display:grid;place-items:center;font-size:21px;font-weight:800}.brand{font-size:19px;font-weight:700}.subtitle{font-size:12px;color:var(--muted);margin-top:3px}
            .hero{display:flex;justify-content:space-between;align-items:end;gap:20px;margin-bottom:20px}.hero h1{font-size:32px;letter-spacing:-1px;margin:0 0 6px}.hero p{color:var(--muted);margin:0}.search{width:min(320px,100%);background:var(--panel);border:1px solid var(--line);border-radius:12px;padding:11px 14px;color:var(--text);font:inherit;outline:none}.search:focus{border-color:#62666f}
            .list{border:1px solid var(--line);border-radius:16px;overflow:hidden;background:var(--panel)}.row{display:grid;grid-template-columns:minmax(0,1fr) minmax(120px,.7fr) 54px 38px;align-items:center;gap:14px;padding:12px 16px;border-bottom:1px solid var(--line);cursor:pointer}.row:last-child{border:0}.row:hover,.row.active{background:#222329}.cover{width:48px;height:48px;border-radius:8px;object-fit:cover;background:#292a30;flex:none}.title{font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.artist,.album,.duration,.empty{color:var(--muted);font-size:13px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.play{border:0;background:transparent;color:var(--accent);font-size:18px;cursor:pointer}.empty{padding:28px;text-align:center}.player{position:fixed;bottom:0;left:0;right:0;background:#191a1feF;backdrop-filter:blur(18px);border-top:1px solid var(--line);padding:13px 24px;display:grid;grid-template-columns:minmax(0,1fr) minmax(180px,520px) minmax(0,1fr);gap:20px;align-items:center}.now{display:flex;align-items:center;gap:11px;min-width:0}.now-meta{min-width:0}.now-title{font-size:13px;font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.now-artist{font-size:12px;color:var(--muted);margin-top:4px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}audio{width:100%;height:38px}.count{text-align:right;color:var(--muted);font-size:12px}
            @media(max-width:650px){.shell{padding:22px 14px 120px}.hero{align-items:stretch;flex-direction:column}.hero h1{font-size:28px}.search{width:100%}.row{grid-template-columns:minmax(0,1fr) 38px;gap:10px;padding:11px}.album,.duration{display:none}.player{grid-template-columns:minmax(0,1fr) minmax(120px,1.2fr);gap:12px;padding:10px 14px}.player audio{grid-column:2;grid-row:1}.count{display:none}}
          </style>
        </head>
        <body>
          <main class="shell">
            <header class="top"><div class="mark">♪</div><div><div class="brand">Nino Music</div><div class="subtitle">Sua biblioteca, em qualquer tela</div></div></header>
            <section class="hero"><div><h1>Biblioteca</h1><p id="summary">Carregando músicas…</p></div><input id="search" class="search" type="search" placeholder="Buscar música, artista ou álbum" aria-label="Buscar"></section>
            <section id="list" class="list" aria-live="polite"><div class="empty">Carregando biblioteca…</div></section>
          </main>
          <footer class="player"><div class="now"><img id="current-cover" class="cover" alt="" hidden><div class="now-meta"><div id="current-title" class="now-title">Selecione uma música</div><div id="current-artist" class="now-artist">Nino Music</div></div></div><audio id="audio" controls preload="none"></audio><div id="count" class="count"></div></footer>
          <script>
            const list=document.getElementById('list'),search=document.getElementById('search'),audio=document.getElementById('audio');let tracks=[],currentId=null;
            const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
            const duration=n=>{n=Number(n)||0;return Math.floor(n/60)+':'+String(n%60).padStart(2,'0')};
            function render(){const q=search.value.trim().toLocaleLowerCase();const shown=tracks.filter(t=>[t.musicTitle,t.artist,t.album].join(' ').toLocaleLowerCase().includes(q));document.getElementById('summary').textContent=`${tracks.length.toLocaleString('pt-BR')} músicas na biblioteca`;document.getElementById('count').textContent=`${shown.length.toLocaleString('pt-BR')} faixas`;list.innerHTML=shown.length?shown.map(t=>`<article class="row ${currentId===t.idServer?'active':''}" data-id="${t.idServer}" tabindex="0"><div><div class="title">${esc(t.musicTitle||'Sem título')}</div><div class="artist">${esc(t.artist||'Artista desconhecido')}</div></div><div class="album">${esc(t.album||'')}</div><div class="duration">${duration(t.duration)}</div><button class="play" aria-label="Reproduzir">▶</button></article>`).join(''):'<div class="empty">Nenhuma música encontrada.</div>';list.querySelectorAll('.row').forEach(row=>{const play=()=>start(Number(row.dataset.id));row.addEventListener('click',play);row.addEventListener('keydown',e=>{if(e.key==='Enter'||e.key===' '){e.preventDefault();play()}})})}
            function start(id){const track=tracks.find(t=>Number(t.idServer)===id);if(!track)return;currentId=id;document.getElementById('current-title').textContent=track.musicTitle||'Sem título';document.getElementById('current-artist').textContent=track.artist||'Artista desconhecido';const cover=document.getElementById('current-cover');cover.hidden=false;cover.src=`/getCover/${id}`;cover.onerror=()=>{cover.hidden=true};audio.src=`/playMusic/${id}`;audio.play().catch(()=>{});render()}
            search.addEventListener('input',render);fetch('/listMusic').then(r=>{if(!r.ok)throw Error();return r.json()}).then(data=>{tracks=Array.isArray(data)?data:[];render()}).catch(()=>{list.innerHTML='<div class="empty">Não foi possível carregar a biblioteca. Atualize a página.</div>';document.getElementById('summary').textContent='Servidor indisponível'})
          </script>
        </body>
        </html>
        """#
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
        if arrayParam.count > 1 {
            let param = arrayParam[1]
            guard let musicId = Int(param) else { return response(statusCode: 404) }
            let path = musicPath(for: musicId)
            guard let path, FileManager.default.fileExists(atPath: path) else {
                logs.insert(ServerLog(dateTime: Date.now,
                                      type: .error,
                                      descr: "Arquivo de música não encontrado!"), at: 0)
                return response(statusCode: 404)
            }
            logs.insert(ServerLog(dateTime: Date.now,
                                  type: .info,
                                  descr: "Enviada música do arquivo \"\(URL(fileURLWithPath: path).lastPathComponent)\"!"), at: 0)
            return GCDWebServerFileResponse(file: path, byteRange: request.byteRange) ?? response(statusCode: 404)
        } else {
            self.logs.insert(ServerLog(dateTime: Date.now,
                                       type: .error,
                                       descr: "Solicitação sem parâmero!"), at: 0)
            return response(statusCode: 400)
        }
    }
    
    private func listMusic() -> GCDWebServerDataResponse {
        let musics = fetchMusicsRemote()
        let data = (try? JSONEncoder().encode(musics)) ?? Data("[]".utf8)
        self.logs.insert(ServerLog(dateTime: Date.now,
                                   type: .info,
                                   descr: "Enviada lista de músicas."), at: 0)
        return GCDWebServerDataResponse(data: data, contentType: "application/json")
    }

    private func fetchMusicsRemote() -> [Music] {
        let sql = """
        SELECT \(DbConstants.TableMusic.tableName).\(DbConstants.TableMusic.colMusicId),
               \(DbConstants.TableArtist.colArtist), \(DbConstants.TableMusic.colTitle),
               \(DbConstants.TableMusic.colTrack), \(DbConstants.TableMusic.colDuration),
               \(DbConstants.TableAlbum.colAlbum), \(DbConstants.TableGenre.colGenre),
               \(DbConstants.TableAlbum.colYear), \(DbConstants.TableMusic.colHasLyrics)
        FROM \(DbConstants.TableMusic.tableName)
        INNER JOIN \(DbConstants.TableArtist.tableName) ON \(DbConstants.TableArtist.tableName).\(DbConstants.TableArtist.colArtistId) = \(DbConstants.TableMusic.colIdArtist)
        INNER JOIN \(DbConstants.TableAlbum.tableName) ON \(DbConstants.TableAlbum.tableName).\(DbConstants.TableAlbum.colAlbumId) = \(DbConstants.TableMusic.colIdAlbum)
        INNER JOIN \(DbConstants.TableGenre.tableName) ON \(DbConstants.TableGenre.tableName).\(DbConstants.TableGenre.colGenreId) = \(DbConstants.TableMusic.colIdGenre)
        ORDER BY \(DbConstants.TableMusic.colTitle), \(DbConstants.TableArtist.colArtist)
        """
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else { return [] }
        var musics = [Music]()
        while sqlite3_step(statement) == SQLITE_ROW {
            func text(_ column: Int32) -> String {
                guard let value = sqlite3_column_text(statement, column) else { return "" }
                return String(cString: value)
            }
            let sequence = musics.count + 1
            musics.append(Music(seq: sequence,
                                idServer: Int(sqlite3_column_int(statement, 0)),
                                artist: text(1),
                                album: text(5),
                                year: Int(sqlite3_column_int(statement, 7)),
                                track: Int(sqlite3_column_int(statement, 3)),
                                musicTitle: text(2),
                                genre: text(6),
                                duration: Int(sqlite3_column_int(statement, 4)),
                                filePath: "",
                                hasLyric: sqlite3_column_int(statement, 8) == 1,
                                isFavorite: false,
                                lastUpdate: .distantPast,
                                lastExecution: .distantPast,
                                countExecution: 0))
        }
        return musics
    }
    
    private func getCover(arrayParam: [String.SubSequence]) -> GCDWebServerDataResponse {
        guard arrayParam.count > 1, let musicId = Int(arrayParam[1]) else { return response(statusCode: 400) }
        guard let path = musicPath(for: musicId), FileManager.default.fileExists(atPath: path) else {
            return response(statusCode: 404)
        }
        let normalizedPath = URL(fileURLWithPath: path).standardizedFileURL.path
        coverCacheLock.lock()
        musicCoverKeys[musicId] = normalizedPath
        coverCacheLock.unlock()
        let cacheKey = normalizedPath as NSString
        if let cachedData = coverResponseCache.object(forKey: cacheKey) {
            return GCDWebServerDataResponse(data: cachedData as Data, contentType: "image/jpeg")
        }
        guard let sourceData = Id3TagUtils.coverImageData(path: path),
              let image = NSImage(data: sourceData),
              let resized = resizedCoverImage(image, maxPixelSize: 240),
              let cgImage = resized.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let jpegData = NSBitmapImageRep(cgImage: cgImage).representation(using: .jpeg, properties: [.compressionFactor: 0.72]) else {
            return response(statusCode: 404)
        }
        coverResponseCache.setObject(jpegData as NSData, forKey: cacheKey)
        return GCDWebServerDataResponse(data: jpegData, contentType: "image/jpeg")
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
                                             hasLyric: hasLyric,
                                             isFavorite: false,
                                             lastUpdate: Date(),
                                             lastExecution: Date(),
                                             countExecution: 0))
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

    private func musicPath(for id: Int) -> String? {
        let sql = "SELECT \(DbConstants.TableMusic.colFilePath) FROM \(DbConstants.TableMusic.tableName) WHERE \(DbConstants.TableMusic.colMusicId) = ?"
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else { return nil }
        sqlite3_bind_int(statement, 1, Int32(id))
        guard sqlite3_step(statement) == SQLITE_ROW,
              let rawPath = sqlite3_column_text(statement, 0) else { return nil }
        let storedPath = String(cString: rawPath)
        if let fileURL = URL(string: storedPath), fileURL.isFileURL {
            return fileURL.path
        }
        return storedPath.removingPercentEncoding ?? storedPath
    }

    private func resizedCoverImage(_ image: NSImage, maxPixelSize: CGFloat) -> NSImage? {
        guard image.size.width > 0, image.size.height > 0 else { return nil }
        let scale = min(maxPixelSize / image.size.width, maxPixelSize / image.size.height, 1)
        guard scale < 1 else { return image }
        let newSize = NSSize(width: image.size.width * scale, height: image.size.height * scale)
        let resizedImage = NSImage(size: newSize)
        resizedImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize),
                   from: NSRect(origin: .zero, size: image.size),
                   operation: .copy,
                   fraction: 1)
        resizedImage.unlockFocus()
        return resizedImage
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
