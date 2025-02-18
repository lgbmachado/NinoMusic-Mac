//
//  MusicLoadingViewController.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 21/09/23.
//

import Cocoa

class MusicLoadingViewController: NSViewController {

    
    @IBOutlet weak var imgLoading: NSImageView!
    @IBOutlet weak var imgOk: NSImageView!
    @IBOutlet weak var txtMsg: NSTextField!
    @IBOutlet weak var btnOk: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.window?.center()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
    }
    
    func updateText(musicsLoaded: Int) {
        txtMsg.stringValue = "\(musicsLoaded) música(s) carregada(s)!"
        self.view.displayIfNeeded()
    }
    
    func FinishLoad(musicsLoaded: Int) {
        imgLoading.isHidden = true
        imgOk.isHidden = false
        btnOk.isEnabled = true
    }
    
    
    @IBAction func btnOkClick(_ sender: Any) {
        self.dismiss(self)
    }
}
