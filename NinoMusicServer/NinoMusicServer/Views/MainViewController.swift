//
//  ViewController.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 01/09/22.
//

import AVFAudio
import Cocoa
import GCDWebServer

enum ChanelMeter {
    case right
    case left
}

class MainViewController: NSViewController {
    
    var musicsListViewModel: MusicsListViewModel?
    var musicLoadingViewController: MusicLoadingViewController?
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var btnPrevMusic: NSButton!
    @IBOutlet weak var btnPlayPauseMusic: NSButton!
    @IBOutlet weak var btnStopMusic: NSButton!
    @IBOutlet weak var btnNextMusic: NSButton!
    @IBOutlet weak var btnEditMusicInfo: NSButtonCell!
    @IBOutlet weak var txtStatus: NSTextField!
    
    
    var player: AVAudioPlayer?
    private var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        updateTableView()
        self.view.window?.center()
    }
    
    private func updateTableView() {
        let musicDb = Database(databasePath: "/Users/nino/MusicDatabase.db")
        musicDb.listMusics { musicsList in
            if let musicsList = musicsList {
                self.musicsListViewModel = MusicsListViewModel(musics: musicsList)
                self.txtStatus.stringValue = "\(musicsList.count) musica(s) disponíveis"
                self.tableView.reloadData()
            }
        }
        musicDb.closeDatabase()
    }
    
    @IBAction func openDirClick(_ sender: Any) {
        let dialog = NSOpenPanel()
        dialog.title = "Selecione o diretório com as músicas"
        dialog.showsResizeIndicator = true;
        dialog.showsHiddenFiles = false;
        dialog.canChooseFiles = false;
        dialog.canChooseDirectories = true;
        
        if (dialog.runModal() ==  NSApplication.ModalResponse.OK) {
            if let result = dialog.url {
                
                self.musicLoadingViewController = MusicLoadingViewController()
                
                DispatchQueue.global(qos: .userInitiated).async {
                    let path: String = result.path
                    
                    let listMusics = ListFileMusic()
                    listMusics.delegate = self
                    
                    listMusics.loadMusics(path: path) { musicsLoaded in
                        if let musicsLoaded = musicsLoaded {
                            DispatchQueue.main.async {
                                self.musicLoadingViewController?.FinishLoad(musicsLoaded: musicsLoaded)
                                self.updateTableView()
                            }
                        }
                    }
                }
                if let musicLoadingViewController = self.musicLoadingViewController {
                    self.presentAsModalWindow(musicLoadingViewController)
                }
            }
        } else {
            return
        }
    }
    
    @IBAction func playPauseMusicClick(_ sender: Any) {
        if let url = URL(string: self.musicsListViewModel?.musicAtIndex(self.tableView.selectedRow).filePath ?? "") {
            do {
                player = try AVAudioPlayer(contentsOf: url)
                guard let player = player else { return }
                
                player.prepareToPlay()
                player.isMeteringEnabled = true
                player.play()
                
                if player.isPlaying {
                    btnPrevMusic.isEnabled = true
                    btnStopMusic.isEnabled = true
                    btnNextMusic.isEnabled = true
                }
                
            } catch let error as NSError {
                print(error.description)
            }
        }
    }
    
    @IBAction func stopMusicClick(_ sender: Any) {
        if let player = self.player {
            if player.isPlaying {
                player.stop()
                btnPrevMusic.isEnabled = false
                btnStopMusic.isEnabled = false
                btnNextMusic.isEnabled = false
            }
        }
    }
    
    @IBAction func editMusicInfoClick(_ sender: Any) {
        if let musicPath = self.musicsListViewModel?.musicAtIndex(self.tableView.selectedRow).filePath {
            lazy var musicDetailViewController = MusicDetailViewController(musicPath: musicPath)
            self.presentAsModalWindow(musicDetailViewController)
        }
    }
    
    @IBAction func startMusicServerClick(_ sender: Any) {
        let startServerDlg = NSAlert()
        startServerDlg.messageText = "Iniciar servidor de música?"
        startServerDlg.informativeText = "Iniciando o servidor, as músicas ficarão disponíveis em outros dipositivos."
        startServerDlg.icon = NSImage(named: NSImage.networkName)
        startServerDlg.addButton(withTitle: "Sim")
        startServerDlg.addButton(withTitle: "Não")
        startServerDlg.alertStyle = .informational
        if startServerDlg.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn {
            let webServer = GCDWebServer()
            webServer.addDefaultHandler(forMethod: "GET", request: GCDWebServerRequest.self, processBlock: {request in
                let arrayParam = request.path.split(separator: "/")
                let command = arrayParam.first
                var result = GCDWebServerDataResponse()
                switch command {
                case "playMusic":
                    if arrayParam.count > 1 {
                        let param = arrayParam[1]
                        let musicDb = Database(databasePath: "/Users/nino/MusicDatabase.db")
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
                case "listMusic":
                    var data = Data()
                    let musicDb = Database(databasePath: "/Users/nino/MusicDatabase.db")
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
                default:
                    break
                }
                return GCDWebServerDataResponse(html: "<html><body><p>ERRO: COMANDO INVÁLIDO: \"\(request.path)\"</p></body></html>")!
            })
            webServer.start(withPort: 8080, bonjourName: "Nino Music Server")
        }
        
    }
    
}

extension MainViewController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let currentMusic = self.musicsListViewModel?.musicAtIndex(row)
        if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "idColMusic") {
            guard let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "idCelMusic"), owner: self) as? NSTableCellView
            else {
                return nil
            }
            cellView.textField?.stringValue = currentMusic?.title ?? ""
            return cellView
        } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "idColArtist") {
            guard let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "idCelArtist"), owner: self) as? NSTableCellView
            else {
                return nil
            }
            cellView.textField?.stringValue = currentMusic?.artist ?? ""
            return cellView
        } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "idColAlbum") {
            guard let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "idCelAlbum"), owner: self) as? NSTableCellView
            else {
                return nil
            }
            cellView.textField?.stringValue = currentMusic?.album ?? ""
            return cellView
        } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "idColYear") {
            guard let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "idCelYear"), owner: self) as? NSTableCellView
            else {
                return nil
            }
            cellView.textField?.stringValue = String("\(currentMusic?.year ?? "")")
            return cellView
        } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "idColTrack") {
            guard let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "idCelTrack"), owner: self) as? NSTableCellView
            else {
                return nil
            }
            cellView.textField?.stringValue = String("\(currentMusic?.track ?? 0)")
            return cellView
        } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "idColGenre") {
            guard let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "idCelGenre"), owner: self) as? NSTableCellView
            else {
                return nil
            }
            cellView.textField?.stringValue = currentMusic?.genre ?? ""
            return cellView
        }else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "idColDuration") {
            guard let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "idCelDuration"), owner: self) as? NSTableCellView
            else {
                return nil
            }
            cellView.textField?.stringValue = String().secondsToTime(seconds: currentMusic?.duration ?? 0) 
            return cellView
        } else {
        }
        return nil
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        if let rows = self.musicsListViewModel?.numberOfRowsInSection(1) {
            if row >= 0 && row < rows {
                btnPlayPauseMusic.isEnabled = true
                btnEditMusicInfo.isEnabled = true
            }
        }
        return true
    }
    
}

extension MainViewController: ListFileMusicDelegate {
    
    func musicLoading(musicsLoaded: Int) {
        DispatchQueue.main.async {
            self.musicLoadingViewController?.updateText(musicsLoaded: musicsLoaded)
        }
    }
}

extension MainViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.musicsListViewModel?.numberOfRowsInSection(1) ?? 0
    }
}

