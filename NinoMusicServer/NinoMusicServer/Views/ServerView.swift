//
//  ServerView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 05/08/24.
//

import SwiftUI

struct ServerView: View {
    let musicServer = MusicServer()
    @State var tableData = [ServerLog]()
    
    var body: some View {
        Table(tableData) {
            TableColumn("Data/Hora") {serverLog in
                Text(DateString(serverLog.dateTime))
            }
            .width(140)
            TableColumn("Tipo") { serverLog in
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
            TableColumn("Descrição", value: \.descr)
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .navigation) {
                HStack {
                    Button("", systemImage: "flag.pattern.checkered.circle", action: {
                        StartMusicServer()
                        tableData.insert(ServerLog(dateTime: Date.now,
                                                   type: .info,
                                                   descr: "Servidor iniciado com sucesso!"), at: 0)
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


#Preview {
    ServerView()
}
