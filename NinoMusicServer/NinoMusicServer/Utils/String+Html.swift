//
//  String+Html.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 14/10/22.
//

import Foundation

extension String {
    var htmlEntitiesEncoded: String {
        struct My {
            static let dict = ["<":"&lt;", ">":"&gt;", "\"":"&quot;", "'":"&apos;", "&":"&amp;"]
            static let pattern = try! RegularExpression(pattern: "[<>\"'&]", options: []) {
                string, _ in
                return dict[string]!
            }
        }
        return My.pattern.stringByReplacingMatchesInString(self)
    }
}
