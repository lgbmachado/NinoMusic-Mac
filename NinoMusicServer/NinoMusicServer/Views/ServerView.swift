//
//  ServerView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 05/08/24.
//

import SwiftUI

struct ServerView: View {
    @ObservedObject var serverViewModel: ServerViewModel
    
    var tableData: [ServerLog] {
        return serverViewModel.logs
    }
    
    @State private var showAlert = false
    @State private var disableButtonStartServer = false
    @State private var disableButtonStoptServer = true
    
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
                serverViewModel.startMusicServer()
            }
            Button(LocalizedStringKey("text_no"), role: .cancel) {
            }
        }
        .dialogIcon(Image(systemName: "server.rack"))
        .toolbar {
            ToolbarItem(placement: .navigation) {
                HStack {
                    Button(String(), systemImage: "flag.pattern.checkered.circle", action: {
                        showAlert = true
                        disableButtonStartServer = true
                        disableButtonStoptServer = false
                    })
                    .font(.system(size: 30))
                    .buttonStyle(.borderless)
                    .disabled(disableButtonStartServer)
                    
                    Button(String(), systemImage: "stop.circle", action: {
                        serverViewModel.stopServer()
                        disableButtonStartServer = false
                        disableButtonStoptServer = true
                    })
                    .font(.system(size: 30))
                    .buttonStyle(.borderless)
                    .disabled(disableButtonStoptServer)
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
}


#Preview {
    ServerView(serverViewModel: ServerViewModel())
}
