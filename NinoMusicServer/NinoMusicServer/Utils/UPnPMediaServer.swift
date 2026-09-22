import Darwin
import Foundation

struct UPnPMediaServer {
    let deviceUUID: String

    func deviceDescription(serverName: String, baseURL: String) -> String {
        """
        <?xml version="1.0" encoding="utf-8"?>
        <root xmlns="urn:schemas-upnp-org:device-1-0">
          <specVersion><major>1</major><minor>0</minor></specVersion>
          <URLBase>\(baseURL.xmlEscaped)/</URLBase>
          <device>
            <deviceType>urn:schemas-upnp-org:device:MediaServer:1</deviceType>
            <friendlyName>\(serverName.xmlEscaped)</friendlyName>
            <manufacturer>Nino Music</manufacturer>
            <modelName>Nino Music Server</modelName>
            <UDN>uuid:\(deviceUUID)</UDN>
            <serviceList>
              <service>
                <serviceType>urn:schemas-upnp-org:service:ContentDirectory:1</serviceType>
                <serviceId>urn:upnp-org:serviceId:ContentDirectory</serviceId>
                <SCPDURL>/upnp/content-directory.xml</SCPDURL>
                <controlURL>/upnp/control/content-directory</controlURL>
                <eventSubURL>/upnp/event/content-directory</eventSubURL>
              </service>
              <service>
                <serviceType>urn:schemas-upnp-org:service:ConnectionManager:1</serviceType>
                <serviceId>urn:upnp-org:serviceId:ConnectionManager</serviceId>
                <SCPDURL>/upnp/connection-manager.xml</SCPDURL>
                <controlURL>/upnp/control/connection-manager</controlURL>
                <eventSubURL>/upnp/event/connection-manager</eventSubURL>
              </service>
            </serviceList>
          </device>
        </root>
        """
    }

    func contentDirectoryDescription() -> String {
        """
        <?xml version="1.0" encoding="utf-8"?>
        <scpd xmlns="urn:schemas-upnp-org:service-1-0">
          <specVersion><major>1</major><minor>0</minor></specVersion>
          <actionList>
                        <action><name>GetSearchCapabilities</name><argumentList><argument><name>SearchCaps</name><direction>out</direction><relatedStateVariable>SearchCapabilities</relatedStateVariable></argument></argumentList></action>
                        <action><name>GetSortCapabilities</name><argumentList><argument><name>SortCaps</name><direction>out</direction><relatedStateVariable>SortCapabilities</relatedStateVariable></argument></argumentList></action>
                        <action><name>GetSystemUpdateID</name><argumentList><argument><name>Id</name><direction>out</direction><relatedStateVariable>SystemUpdateID</relatedStateVariable></argument></argumentList></action>
            <action><name>Browse</name><argumentList>
              <argument><name>ObjectID</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_ObjectID</relatedStateVariable></argument>
              <argument><name>BrowseFlag</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_BrowseFlag</relatedStateVariable></argument>
              <argument><name>Filter</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_Filter</relatedStateVariable></argument>
              <argument><name>StartingIndex</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_Index</relatedStateVariable></argument>
              <argument><name>RequestedCount</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_Count</relatedStateVariable></argument>
              <argument><name>SortCriteria</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_SortCriteria</relatedStateVariable></argument>
              <argument><name>Result</name><direction>out</direction><relatedStateVariable>A_ARG_TYPE_Result</relatedStateVariable></argument>
              <argument><name>NumberReturned</name><direction>out</direction><relatedStateVariable>A_ARG_TYPE_Count</relatedStateVariable></argument>
              <argument><name>TotalMatches</name><direction>out</direction><relatedStateVariable>A_ARG_TYPE_Count</relatedStateVariable></argument>
              <argument><name>UpdateID</name><direction>out</direction><relatedStateVariable>A_ARG_TYPE_UpdateID</relatedStateVariable></argument>
            </argumentList></action>
          </actionList>
          <serviceStateTable>
                        <stateVariable sendEvents="no"><name>SearchCapabilities</name><dataType>string</dataType></stateVariable>
                        <stateVariable sendEvents="no"><name>SortCapabilities</name><dataType>string</dataType></stateVariable>
                        <stateVariable sendEvents="yes"><name>SystemUpdateID</name><dataType>ui4</dataType></stateVariable>
            <stateVariable sendEvents="no"><name>A_ARG_TYPE_ObjectID</name><dataType>string</dataType></stateVariable>
            <stateVariable sendEvents="no"><name>A_ARG_TYPE_BrowseFlag</name><dataType>string</dataType><allowedValueList><allowedValue>BrowseMetadata</allowedValue><allowedValue>BrowseDirectChildren</allowedValue></allowedValueList></stateVariable>
            <stateVariable sendEvents="no"><name>A_ARG_TYPE_Filter</name><dataType>string</dataType></stateVariable>
            <stateVariable sendEvents="no"><name>A_ARG_TYPE_Index</name><dataType>ui4</dataType></stateVariable>
            <stateVariable sendEvents="no"><name>A_ARG_TYPE_Count</name><dataType>ui4</dataType></stateVariable>
            <stateVariable sendEvents="no"><name>A_ARG_TYPE_SortCriteria</name><dataType>string</dataType></stateVariable>
            <stateVariable sendEvents="no"><name>A_ARG_TYPE_Result</name><dataType>string</dataType></stateVariable>
            <stateVariable sendEvents="no"><name>A_ARG_TYPE_UpdateID</name><dataType>ui4</dataType></stateVariable>
          </serviceStateTable>
        </scpd>
        """
    }

    func connectionManagerDescription() -> String {
        """
        <?xml version="1.0" encoding="utf-8"?>
        <scpd xmlns="urn:schemas-upnp-org:service-1-0">
          <specVersion><major>1</major><minor>0</minor></specVersion>
                    <actionList>
                        <action><name>GetProtocolInfo</name></action>
                        <action><name>GetCurrentConnectionIDs</name></action>
                    </actionList>
                    <serviceStateTable>
                        <stateVariable sendEvents="yes"><name>SourceProtocolInfo</name><dataType>string</dataType></stateVariable>
                        <stateVariable sendEvents="yes"><name>SinkProtocolInfo</name><dataType>string</dataType></stateVariable>
                        <stateVariable sendEvents="yes"><name>CurrentConnectionIDs</name><dataType>string</dataType></stateVariable>
                    </serviceStateTable>
        </scpd>
        """
    }

    func browseResponse(requestData: Data, musics: [Music], baseURL: String) -> String {
        let request = String(data: requestData, encoding: .utf8) ?? ""
        let objectID = request.xmlValue(named: "ObjectID") ?? "0"
        let browseMetadata = request.xmlValue(named: "BrowseFlag") == "BrowseMetadata"
        let startingIndex = Int(request.xmlValue(named: "StartingIndex") ?? "0") ?? 0
        let requestedCount = Int(request.xmlValue(named: "RequestedCount") ?? "0") ?? 0
        let allObjects = browseMetadata
            ? metadata(for: objectID, musics: musics, baseURL: baseURL)
            : children(of: objectID, musics: musics, baseURL: baseURL)
        let start = min(max(0, startingIndex), allObjects.count)
        let end = requestedCount == 0 ? allObjects.count : min(allObjects.count, start + requestedCount)
        let selectedObjects = Array(allObjects[start..<end])
        let didl = """
        <DIDL-Lite xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/">\(selectedObjects.joined())</DIDL-Lite>
        """
        return soapEnvelope(action: "Browse", service: "ContentDirectory", content: """
        <Result>\(didl.xmlEscaped)</Result><NumberReturned>\(selectedObjects.count)</NumberReturned><TotalMatches>\(allObjects.count)</TotalMatches><UpdateID>1</UpdateID>
        """)
    }

    func protocolInfoResponse() -> String {
        soapEnvelope(action: "GetProtocolInfo", service: "ConnectionManager", content: "<Source>http-get:*:audio/mpeg:*</Source><Sink></Sink>")
    }

    func contentDirectoryResponse(requestData: Data, musics: [Music], baseURL: String) -> String {
        let request = String(data: requestData, encoding: .utf8) ?? ""
        if request.range(of: "GetSearchCapabilities", options: .caseInsensitive) != nil {
            return soapEnvelope(action: "GetSearchCapabilities", service: "ContentDirectory", content: "<SearchCaps></SearchCaps>")
        }
        if request.range(of: "GetSortCapabilities", options: .caseInsensitive) != nil {
            return soapEnvelope(action: "GetSortCapabilities", service: "ContentDirectory", content: "<SortCaps>dc:title,upnp:artist,upnp:album</SortCaps>")
        }
        if request.range(of: "GetSystemUpdateID", options: .caseInsensitive) != nil {
            return soapEnvelope(action: "GetSystemUpdateID", service: "ContentDirectory", content: "<Id>1</Id>")
        }
        return browseResponse(requestData: requestData, musics: musics, baseURL: baseURL)
    }

    func connectionManagerResponse(requestData: Data) -> String {
        let request = String(data: requestData, encoding: .utf8) ?? ""
        if request.range(of: "GetCurrentConnectionIDs", options: .caseInsensitive) != nil {
            return soapEnvelope(action: "GetCurrentConnectionIDs", service: "ConnectionManager", content: "<ConnectionIDs>0</ConnectionIDs>")
        }
        return protocolInfoResponse()
    }

    private func children(of objectID: String, musics: [Music], baseURL: String) -> [String] {
        switch objectID {
        case "0":
            return [container(id: "music", parentID: "0", title: "Músicas", childCount: 3)]
        case "music":
            return [
                container(id: "all", parentID: "music", title: "Todas as músicas", childCount: musics.count),
                container(id: "albums", parentID: "music", title: "Álbuns", childCount: albums(in: musics).count),
                container(id: "artists", parentID: "music", title: "Artistas", childCount: artists(in: musics).count)
            ]
        case "all":
            return musics.map { item($0, parentID: "all", baseURL: baseURL) }
        case "albums":
            return albums(in: musics).enumerated().map { index, album in
                let albumMusics = musics.filter { $0.album == album }
                let artworkURI = albumMusics.first.map { "\(baseURL)/getCover/\($0.idServer)" }
                return container(id: "album:\(index)", parentID: "albums", title: album, childCount: albumMusics.count, artworkURI: artworkURI)
            }
        case "artists":
            return artists(in: musics).enumerated().map { index, artist in
                container(id: "artist:\(index)", parentID: "artists", title: artist, childCount: musics.filter { $0.artist == artist }.count)
            }
        default:
            if objectID.hasPrefix("album:"), let index = Int(objectID.dropFirst(6)), albums(in: musics).indices.contains(index) {
                return musics.filter { $0.album == albums(in: musics)[index] }.map { item($0, parentID: objectID, baseURL: baseURL) }
            }
            if objectID.hasPrefix("artist:"), let index = Int(objectID.dropFirst(7)), artists(in: musics).indices.contains(index) {
                return musics.filter { $0.artist == artists(in: musics)[index] }.map { item($0, parentID: objectID, baseURL: baseURL) }
            }
            return []
        }
    }

    private func metadata(for objectID: String, musics: [Music], baseURL: String) -> [String] {
        if objectID == "0" { return [container(id: "0", parentID: "-1", title: "Nino Music", childCount: 1)] }
        if objectID == "music" { return [container(id: "music", parentID: "0", title: "Músicas", childCount: 3)] }
        if objectID == "all" { return [container(id: "all", parentID: "music", title: "Todas as músicas", childCount: musics.count)] }
        if let music = musics.first(where: { "track:\($0.idServer)" == objectID }) {
            return [item(music, parentID: "all", baseURL: baseURL)]
        }
        return children(of: objectID.hasPrefix("album:") ? "albums" : "artists", musics: musics, baseURL: baseURL)
            .filter { $0.contains("id=\"\(objectID)\"") }
    }

    private func item(_ music: Music, parentID: String, baseURL: String) -> String {
        let duration = TimeInterval(music.duration).upnpDuration
        return """
        <item id="track:\(music.idServer)" parentID="\(parentID)" restricted="1"><dc:title>\(music.musicTitle.xmlEscaped)</dc:title><upnp:artist>\(music.artist.xmlEscaped)</upnp:artist><upnp:album>\(music.album.xmlEscaped)</upnp:album><upnp:genre>\(music.genre.xmlEscaped)</upnp:genre><upnp:albumArtURI dlna:profileID="JPEG_TN" xmlns:dlna="urn:schemas-dlna-org:metadata-1-0/">\(baseURL)/getCover/\(music.idServer)</upnp:albumArtURI><res protocolInfo="http-get:*:audio/mpeg:DLNA.ORG_PN=MP3" duration="\(duration)">\(baseURL)/playMusic/\(music.idServer)</res><upnp:class>object.item.audioItem.musicTrack</upnp:class></item>
        """
    }

    private func container(id: String, parentID: String, title: String, childCount: Int, artworkURI: String? = nil) -> String {
        let artwork = artworkURI.map { "<upnp:albumArtURI dlna:profileID=\"JPEG_TN\" xmlns:dlna=\"urn:schemas-dlna-org:metadata-1-0/\">\($0.xmlEscaped)</upnp:albumArtURI>" } ?? ""
        return "<container id=\"\(id)\" parentID=\"\(parentID)\" restricted=\"1\" searchable=\"1\" childCount=\"\(childCount)\"><dc:title>\(title.xmlEscaped)</dc:title>\(artwork)<upnp:class>object.container</upnp:class></container>"
    }

    private func albums(in musics: [Music]) -> [String] {
        Array(Set(musics.map(\.album))).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private func artists(in musics: [Music]) -> [String] {
        Array(Set(musics.map(\.artist))).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private func soapEnvelope(action: String, service: String, content: String) -> String {
        """
        <?xml version="1.0" encoding="utf-8"?>
        <s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body><u:\(action)Response xmlns:u="urn:schemas-upnp-org:service:\(service):1">\(content)</u:\(action)Response></s:Body></s:Envelope>
        """
    }
}

final class SSDPService {
    private let queue = DispatchQueue(label: "NinoMusic.SSDP")
    private var socketDescriptor: Int32 = -1
    private var readSource: DispatchSourceRead?
    private var announceTimer: DispatchSourceTimer?
    private var location = ""
    private var uuid = ""

    func start(location: String, uuid: String) throws {
        stop(sendByebye: false)
        self.location = location
        self.uuid = uuid

        socketDescriptor = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
        guard socketDescriptor >= 0 else { throw POSIXError(.ENOTSOCK) }
        var reuse: Int32 = 1
        setsockopt(socketDescriptor, SOL_SOCKET, SO_REUSEADDR, &reuse, socklen_t(MemoryLayout<Int32>.size))

        var address = sockaddr_in()
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = in_port_t(1900).bigEndian
        address.sin_addr = in_addr(s_addr: INADDR_ANY)
        let bindResult = withUnsafePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { bind(socketDescriptor, $0, socklen_t(MemoryLayout<sockaddr_in>.size)) }
        }
        guard bindResult == 0 else { stop(sendByebye: false); throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }

        var membership = ip_mreq(imr_multiaddr: in_addr(s_addr: inet_addr("239.255.255.250")), imr_interface: in_addr(s_addr: INADDR_ANY))
        guard setsockopt(socketDescriptor, IPPROTO_IP, IP_ADD_MEMBERSHIP, &membership, socklen_t(MemoryLayout<ip_mreq>.size)) == 0 else {
            stop(sendByebye: false)
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }

        let source = DispatchSource.makeReadSource(fileDescriptor: socketDescriptor, queue: queue)
        source.setEventHandler { [weak self] in self?.receiveSearch() }
        source.setCancelHandler { [weak self] in
            guard let self, self.socketDescriptor >= 0 else { return }
            close(self.socketDescriptor)
            self.socketDescriptor = -1
        }
        readSource = source
        source.resume()

        announce(alive: true)
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + 900, repeating: 900)
        timer.setEventHandler { [weak self] in self?.announce(alive: true) }
        announceTimer = timer
        timer.resume()
    }

    func stop(sendByebye: Bool = true) {
        if sendByebye, socketDescriptor >= 0 { announce(alive: false) }
        announceTimer?.cancel()
        announceTimer = nil
        readSource?.cancel()
        readSource = nil
        if socketDescriptor >= 0 {
            close(socketDescriptor)
            socketDescriptor = -1
        }
    }

    private func receiveSearch() {
        var buffer = [UInt8](repeating: 0, count: 8192)
        var sender = sockaddr_storage()
        var senderLength = socklen_t(MemoryLayout<sockaddr_storage>.size)
        let count = withUnsafeMutablePointer(to: &sender) { senderPointer in
            senderPointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { socketAddress in
                recvfrom(socketDescriptor, &buffer, buffer.count, 0, socketAddress, &senderLength)
            }
        }
        guard count > 0 else { return }
        let request = String(decoding: buffer.prefix(count), as: UTF8.self).uppercased()
        guard request.contains("M-SEARCH"), request.contains("SSDP:DISCOVER") else { return }
        let searchTarget = request.components(separatedBy: "\r\n")
            .first(where: { $0.hasPrefix("ST:") })?
            .dropFirst(3).trimmingCharacters(in: .whitespaces) ?? "ssdp:all"
        let supportedTargets = targets.map(\.target)
        let matchingTargets = searchTarget.lowercased() == "ssdp:all"
            ? supportedTargets
            : supportedTargets.filter { $0.lowercased() == searchTarget.lowercased() }
        for target in matchingTargets {
            let response = "HTTP/1.1 200 OK\r\nCACHE-CONTROL: max-age=1800\r\nEXT:\r\nLOCATION: \(location)\r\nSERVER: macOS UPnP/1.0 NinoMusic/1.0\r\nST: \(target)\r\nUSN: \(usn(for: target))\r\n\r\n"
            send(response, to: sender, length: senderLength)
        }
    }

    private func announce(alive: Bool) {
        guard socketDescriptor >= 0 else { return }
        var destination = sockaddr_in()
        destination.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        destination.sin_family = sa_family_t(AF_INET)
        destination.sin_port = in_port_t(1900).bigEndian
        destination.sin_addr = in_addr(s_addr: inet_addr("239.255.255.250"))
        for target in targets.map(\.target) {
            var message = "NOTIFY * HTTP/1.1\r\nHOST: 239.255.255.250:1900\r\nNT: \(target)\r\nNTS: ssdp:\(alive ? "alive" : "byebye")\r\nUSN: \(usn(for: target))\r\n"
            if alive { message += "CACHE-CONTROL: max-age=1800\r\nLOCATION: \(location)\r\nSERVER: macOS UPnP/1.0 NinoMusic/1.0\r\n" }
            message += "\r\n"
            send(message, to: destination)
        }
    }

    private var targets: [(target: String, suffix: String)] {
        [
            ("upnp:rootdevice", "::upnp:rootdevice"),
            ("uuid:\(uuid)", ""),
            ("urn:schemas-upnp-org:device:MediaServer:1", "::urn:schemas-upnp-org:device:MediaServer:1"),
            ("urn:schemas-upnp-org:service:ContentDirectory:1", "::urn:schemas-upnp-org:service:ContentDirectory:1"),
            ("urn:schemas-upnp-org:service:ConnectionManager:1", "::urn:schemas-upnp-org:service:ConnectionManager:1")
        ]
    }

    private func usn(for target: String) -> String {
        guard let entry = targets.first(where: { $0.target == target }) else { return "uuid:\(uuid)" }
        return "uuid:\(uuid)\(entry.suffix)"
    }

    private func send<T>(_ message: String, to address: T, length: socklen_t = socklen_t(MemoryLayout<T>.size)) {
        var address = address
        message.withCString { bytes in
            withUnsafePointer(to: &address) { addressPointer in
                addressPointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    _ = sendto(socketDescriptor, bytes, strlen(bytes), 0, $0, length)
                }
            }
        }
    }

    static func localIPv4Address() -> String? {
        var interfaces: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&interfaces) == 0, let firstInterface = interfaces else { return nil }
        defer { freeifaddrs(interfaces) }

        var fallback: String?
        for interface in sequence(first: firstInterface, next: { $0.pointee.ifa_next }) {
            let flags = Int32(interface.pointee.ifa_flags)
            guard flags & IFF_UP != 0,
                  flags & IFF_LOOPBACK == 0,
                  interface.pointee.ifa_addr.pointee.sa_family == UInt8(AF_INET) else { continue }
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            guard getnameinfo(interface.pointee.ifa_addr,
                              socklen_t(interface.pointee.ifa_addr.pointee.sa_len),
                              &hostname,
                              socklen_t(hostname.count),
                              nil,
                              0,
                              NI_NUMERICHOST) == 0 else { continue }
            let address = String(cString: hostname)
            if String(cString: interface.pointee.ifa_name) == "en0" { return address }
            fallback = fallback ?? address
        }
        return fallback
    }
}

extension String {
    fileprivate var xmlEscaped: String {
        replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }

    fileprivate func xmlValue(named name: String) -> String? {
        let pattern = "<(?:[A-Za-z0-9_-]+:)?\(name)[^>]*>(.*?)</(?:[A-Za-z0-9_-]+:)?\(name)>"
        guard let expression = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]),
              let match = expression.firstMatch(in: self, range: NSRange(startIndex..., in: self)),
              let range = Range(match.range(at: 1), in: self) else { return nil }
        return String(self[range])
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&apos;", with: "'")
            .replacingOccurrences(of: "&amp;", with: "&")
    }
}

extension TimeInterval {
    fileprivate var upnpDuration: String {
        let totalSeconds = max(0, Int(self))
        return String(format: "%02d:%02d:%02d", totalSeconds / 3600, (totalSeconds % 3600) / 60, totalSeconds % 60)
    }
}
