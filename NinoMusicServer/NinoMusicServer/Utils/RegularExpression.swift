//
//  RegularExpression.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 14/10/22.
//

import Foundation

class RegularExpression: NSRegularExpression {
    
    typealias ReplacementBlock = (NSTextCheckingResult, String, Int, String)->String
    typealias SimpleReplacementBlock = (String, Int)->String
    
    private var replacementBlock: ReplacementBlock
    
    init(pattern: String, options: NSRegularExpression.Options, block: @escaping ReplacementBlock) throws {
        self.replacementBlock = block
        try super.init(pattern: pattern, options: options)
    }
    
    convenience init(pattern: String, options: NSRegularExpression.Options, simpleBlock: @escaping SimpleReplacementBlock) throws {
        try self.init(pattern: pattern, options: options, block: {result,string,offset,_ in
            let matchedString = (string as NSString).substring(with: result.range)
            return simpleBlock(matchedString, offset)
        })
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func replacementString(for result: NSTextCheckingResult, in string: String, offset: Int, template templ: String) -> String {
        return self.replacementBlock(result, string, offset, templ)
    }
    
    func stringByReplacingMatchesInString(_ string: String, options: NSRegularExpression.MatchingOptions, range: NSRange) -> String {
        return super.stringByReplacingMatches(in: string, options: options, range: range, withTemplate: "*")
    }
    
    func stringByReplacingMatchesInString(_ string: String, options: NSRegularExpression.MatchingOptions = []) -> String {
        return self.stringByReplacingMatchesInString(string, options: options, range: NSRange(0..<string.utf16.count))
    }
    
    func replaceMatchesInString(_ string: NSMutableString, options: NSRegularExpression.MatchingOptions, range: NSRange) -> Int {
        return super.replaceMatches(in: string, options: options, range: range, withTemplate: "*")
    }
    
    func replaceMatchesInString(_ string: NSMutableString, options: NSRegularExpression.MatchingOptions = []) -> Int {
        return self.replaceMatchesInString(string, options: options, range: NSRange(0..<string.length))
    }
}
