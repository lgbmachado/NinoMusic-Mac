//
//  ViewController.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 01/09/22.
//

import AVFAudio
import Cocoa
import GCDWebServer

class MainViewController: NSViewController {
    
    var musicsListViewModel: MusicsListViewModel?
    var artistsListViewModel: ArtistsListViewModel?
    
    var musicLoadingViewController: MusicLoadingViewController?
    
    @IBOutlet weak var tbvMusics: NSTableView!
    @IBOutlet weak var tbvArtists: NSTableView!
    
    @IBOutlet weak var btnPrevMusic: NSButton!
    @IBOutlet weak var btnPlayPauseMusic: NSButton!
    @IBOutlet weak var btnStopMusic: NSButton!
    @IBOutlet weak var btnNextMusic: NSButton!
    @IBOutlet weak var btnEditMusicInfo: NSButtonCell!
    @IBOutlet weak var txtStatus: NSTextField!
    
    
    var player: AVAudioPlayer?
    private var timer: Timer?
    let musicServer = MusicServer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tbvMusics.delegate = self
        tbvMusics.dataSource = self
        
        tbvArtists.delegate = self
        tbvArtists.dataSource = self
        
        updateTableView()
        self.view.window?.center()
    }
    
    private func updateTableView() {
        let musicDb = Database()
        musicDb.listMusics { musicsList in
            if let musicsList = musicsList {
                self.musicsListViewModel = MusicsListViewModel(musics: musicsList)
                self.txtStatus.stringValue = "\(musicsList.count) musica(s) disponíveis"
                self.tbvMusics.reloadData()
            }
        }
        
        musicDb.listArtists { artistsList in
            if let artistsList = artistsList {
                self.artistsListViewModel = ArtistsListViewModel(musics: artistsList)
                self.tbvArtists.reloadData()
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
        if let url = URL(string: self.musicsListViewModel?.musicAtIndex(self.tbvMusics.selectedRow).filePath ?? "") {
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
        if let musicPath = self.musicsListViewModel?.musicAtIndex(self.tbvMusics.selectedRow).filePath {
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
            musicServer.start()
        }
        
    }
    
}

extension MainViewController: NSTableViewDelegate {
    
    func CellMusicTable(tableView: NSTableView, tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let currentMusic = self.musicsListViewModel?.musicAtIndex(row)
        if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "idMusicColMusic") {
            guard let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "idMusicCelMusic"), owner: self) as? NSTableCellView
            else {
                return nil
            }
            cellView.textField?.stringValue = currentMusic?.title ?? ""
            return cellView
        } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "idMusicColArtist") {
            guard let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "idMusicCelArtist"), owner: self) as? NSTableCellView
            else {
                return nil
            }
            cellView.textField?.stringValue = currentMusic?.artist ?? ""
            return cellView
        } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "idMusicColAlbum") {
            guard let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "idMusicCelAlbum"), owner: self) as? NSTableCellView
            else {
                return nil
            }
            cellView.textField?.stringValue = currentMusic?.album ?? ""
            return cellView
        } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "idMusicColYear") {
            guard let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "idMusicCelYear"), owner: self) as? NSTableCellView
            else {
                return nil
            }
            cellView.textField?.stringValue = String("\(currentMusic?.year ?? "")")
            return cellView
        } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "idMusicColTrack") {
            guard let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "idMusicCelTrack"), owner: self) as? NSTableCellView
            else {
                return nil
            }
            cellView.textField?.stringValue = String("\(currentMusic?.track ?? 0)")
            return cellView
        } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "idMusicColGenre") {
            guard let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "idMusicCelGenre"), owner: self) as? NSTableCellView
            else {
                return nil
            }
            cellView.textField?.stringValue = currentMusic?.genre ?? ""
            return cellView
        }else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "idMusicColDuration") {
            guard let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "idMusicCelDuration"), owner: self) as? NSTableCellView
            else {
                return nil
            }
            cellView.textField?.stringValue = String().secondsToTime(seconds: currentMusic?.duration ?? 0)
            return cellView
        } else {
            return nil
        }
    }
    
    func CellArtistTable(tableView: NSTableView, tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let currentMusic = self.artistsListViewModel?.artistAtIndex(row)
        
        if let isNewArtist = artistsListViewModel?.isNewArtist(row),
           let isNewAlbum = artistsListViewModel?.isNewAlbum(row) {
            if isNewArtist {
                if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "idArtistColArtist") {
                    guard let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "idArtistCelArtist"), owner: self) as? NSTableCellView
                    else {
                        return nil
                    }
                    cellView.textField?.stringValue = currentMusic?.artist ?? ""
                    return cellView
                } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "idArtistColGenre") {
                    guard let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "idArtistCelGenre"), owner: self) as? NSTableCellView
                    else {
                        return nil
                    }
                    cellView.textField?.stringValue = currentMusic?.genre ?? ""
                    return cellView
                } 
                if isNewAlbum {
                    if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "idArtistColAlbum") {
                        guard let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "idArtistCelAlbum"), owner: self) as? NSTableCellView
                        else {
                            return nil
                        }
                        cellView.textField?.stringValue = currentMusic?.album ?? ""
                        return cellView
                    } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "idArtistColYear") {
                        guard let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "idArtistCelYear"), owner: self) as? NSTableCellView
                        else {
                            return nil
                        }
                        cellView.textField?.stringValue = String("\(currentMusic?.year ?? "")")
                        return cellView
                    } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "idArtistColTrack") {
                        guard let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "idArtistCelTrack"), owner: self) as? NSTableCellView
                        else {
                            return nil
                        }
                        cellView.textField?.stringValue = String("\(currentMusic?.track ?? 0)")
                        return cellView
                    } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "idArtistColMusic") {
                        guard let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "idArtistCelMusic"), owner: self) as? NSTableCellView
                        else {
                            return nil
                        }
                        cellView.textField?.stringValue = currentMusic?.title ?? ""
                        return cellView
                    } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "idArtistColDuration") {
                        guard let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "idArtistCelDuration"), owner: self) as? NSTableCellView
                        else {
                            return nil
                        }
                        cellView.textField?.stringValue = String().secondsToTime(seconds: currentMusic?.duration ?? 0)
                        return cellView
                    } else {
                        return nil
                    }
                } else {
                    if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "idArtistColTrack") {
                        guard let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "idArtistCelTrack"), owner: self) as? NSTableCellView
                        else {
                            return nil
                        }
                        cellView.textField?.stringValue = String("\(currentMusic?.track ?? 0)")
                        return cellView
                    } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "idArtistColMusic") {
                        guard let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "idArtistCelMusic"), owner: self) as? NSTableCellView
                        else {
                            return nil
                        }
                        cellView.textField?.stringValue = currentMusic?.title ?? ""
                        return cellView
                    } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "idArtistColDuration") {
                        guard let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "idArtistCelDuration"), owner: self) as? NSTableCellView
                        else {
                            return nil
                        }
                        cellView.textField?.stringValue = String().secondsToTime(seconds: currentMusic?.duration ?? 0)
                        return cellView
                    } else {
                        return nil
                    }
                }
            } else {
                if isNewAlbum {
                    if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "idArtistColAlbum") {
                        guard let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "idArtistCelAlbum"), owner: self) as? NSTableCellView
                        else {
                            return nil
                        }
                        cellView.textField?.stringValue = currentMusic?.album ?? ""
                        return cellView
                    } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "idArtistColYear") {
                        guard let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "idArtistCelYear"), owner: self) as? NSTableCellView
                        else {
                            return nil
                        }
                        cellView.textField?.stringValue = String("\(currentMusic?.year ?? "")")
                        return cellView
                    } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "idArtistColTrack") {
                        guard let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "idArtistCelTrack"), owner: self) as? NSTableCellView
                        else {
                            return nil
                        }
                        cellView.textField?.stringValue = String("\(currentMusic?.track ?? 0)")
                        return cellView
                    } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "idArtistColMusic") {
                        guard let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "idArtistCelMusic"), owner: self) as? NSTableCellView
                        else {
                            return nil
                        }
                        cellView.textField?.stringValue = currentMusic?.title ?? ""
                        return cellView
                    } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "idArtistColDuration") {
                        guard let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "idArtistCelDuration"), owner: self) as? NSTableCellView
                        else {
                            return nil
                        }
                        cellView.textField?.stringValue = String().secondsToTime(seconds: currentMusic?.duration ?? 0)
                        return cellView
                    } else {
                        return nil
                    }
                } else {
                    if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "idArtistColTrack") {
                        guard let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "idArtistCelTrack"), owner: self) as? NSTableCellView
                        else {
                            return nil
                        }
                        cellView.textField?.stringValue = String("\(currentMusic?.track ?? 0)")
                        return cellView
                    } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "idArtistColMusic") {
                        guard let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "idArtistCelMusic"), owner: self) as? NSTableCellView
                        else {
                            return nil
                        }
                        cellView.textField?.stringValue = currentMusic?.title ?? ""
                        return cellView
                    } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "idArtistColDuration") {
                        guard let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "idArtistCelDuration"), owner: self) as? NSTableCellView
                        else {
                            return nil
                        }
                        cellView.textField?.stringValue = String().secondsToTime(seconds: currentMusic?.duration ?? 0)
                        return cellView
                    } else {
                        return nil
                    }
                }
                
            }
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if tableView.tag == 0 {
            return CellMusicTable(tableView: tableView, tableColumn: tableColumn, row: row)
        } else if tableView.tag == 1 {
            return CellArtistTable(tableView: tableView, tableColumn: tableColumn, row: row)
        } else {
            return nil
        }
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
    
    //    func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool {
    //        if tableView.tag == 0 {
    //            return false
    //        } else if tableView.tag == 1 {
    //            if let isNewArtist = artistsListViewModel?.isNewArtist(row) {
    //                return isNewArtist
    //            } else {
    //             return false
    //            }
    //        } else {
    //            return true
    //        }
    //    }
    
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
        if tableView.tag == 0 {
            return self.musicsListViewModel?.numberOfRowsInSection(1) ?? 0
        } else if tableView.tag == 1 {
            return self.musicsListViewModel?.numberOfRowsInSection(1) ?? 0
        } else {
            return 0
        }
        
    }
}

