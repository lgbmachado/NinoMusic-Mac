//
//  MusicDetailViewController.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 17/09/23.
//

import Cocoa
import ID3TagEditor

class MusicDetailViewController: NSViewController {
    
    
    @IBOutlet weak var edtName: NSTextField!
    @IBOutlet weak var edtArtist: NSTextField!
    @IBOutlet weak var edtAlbum: NSTextField!
    @IBOutlet weak var edtYear: NSTextField!
    @IBOutlet weak var edtTrack: NSTextField!
    @IBOutlet weak var cbxGenre: NSComboBox!
    @IBOutlet weak var imgCover: NSImageView!
    @IBOutlet var edtTextView: NSTextView!
    
    private var musicPath: String = ""
    
    init(musicPath: String) {
        super.init(nibName: nil, bundle: nil)
        self.musicPath = (musicPath as NSString).removingPercentEncoding ?? ""
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = (self.musicPath as NSString).lastPathComponent
        let id3TagEditor: ID3TagEditor = ID3TagEditor()
        do {
            let id3Tag = try id3TagEditor.read(from: self.musicPath.replacingOccurrences(of: "file://", with: ""))
            
            edtName.stringValue = ((id3Tag?.frames[.title] as? ID3FrameWithStringContent)?.content ?? "") as String
            edtArtist.stringValue = ((id3Tag?.frames[.artist] as? ID3FrameWithStringContent)?.content ?? "") as String
            edtAlbum.stringValue = ((id3Tag?.frames[ .album] as? ID3FrameWithStringContent)?.content ?? "") as String
            edtYear.stringValue = String(((id3Tag?.frames[.recordingYear] as? ID3FrameWithIntegerContent)?.value ?? 0) as Int)
            edtTrack.stringValue = String(((id3Tag?.frames[.trackPosition] as? ID3FramePartOfTotal)?.part ?? 0) as Int)
            cbxGenre.stringValue = ((id3Tag?.frames[.genre] as? ID3FrameGenre)?.description ?? "") as String
            
            if let coverImage = id3Tag?.frames[.attachedPicture(.frontCover)] as? ID3FrameAttachedPicture {
                imgCover.image = NSImage(data: coverImage.picture)
            }
            if let letra = (id3Tag?.frames[.lyricist] as? ID3FrameGenre)?.description {
                cbxGenre.stringValue = letra
            }
        }
        catch {
            print(error)
        }
        
        self.view.window?.center()
    }
    
    @IBAction func cancelButtonClick(_ sender: Any) {
        self.dismiss(self)
    }
    
    
    @IBAction func saveButtonClick(_ sender: Any) {
        self.dismiss(self)
    }
}
