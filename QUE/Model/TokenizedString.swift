//
//  TokenizedString.swift
//  FindingAnswers
//
//  Created by Krish Kharbanda on 5/22/21.
//  Copyright © 2021 KK Can Code. All rights reserved.
//

import NaturalLanguage

struct TokenizedString {
    private let _tokens: [Substring]
    private let _tokenIDs: [Int]
    
    let original: String
    public var tokens: [Substring] { return _tokens }
    public var tokenIDs: [Int] { return _tokenIDs }
    
    init(_ string: String) {
        original = string
        
        let result = TokenizedString.tokenize(string)
        _tokens = result.tokens
        _tokenIDs = result.tokenIDs
    }
    private static func tokenize(_ string: String) -> (tokens: [Substring], tokenIDs: [Int]) {
        let tokens = wordTokens(from: string)
        return wordpieceTokens(from: tokens)
    }

    private static func wordTokens(from rawString: String) -> [Substring] {
        var wordTokens = [Substring]()

        let tagger = NLTagger(tagSchemes: [.tokenType])
        tagger.string = rawString

        tagger.enumerateTags(in: rawString.startIndex..<rawString.endIndex,
                             unit: .word,
                             scheme: .tokenType,
                             options: [.omitWhitespace]) { (_, range) -> Bool in
            wordTokens.append(rawString[range])
            return true
        }

        return wordTokens
    }
    
    private static func wordpieceTokens(from wordTokens: [Substring]) -> (tokens: [Substring], tokenIDs: [Int]) {
        var wordpieceTokens = [Substring]()
        var wordpieceTokenIDs = [Int]()
        
        for token in wordTokens {
            guard token.count <= 100 else {
                wordpieceTokens.append(token)
                wordpieceTokenIDs.append(QUEVocabulary.unkownTokenID)
                continue
            }
            
            var subTokens = [Substring]()
            var subTokenIDs = [Int]()

            var subToken = token
            
            var foundFirstSubtoken = false

            while !subToken.isEmpty {
                let prefix = foundFirstSubtoken ? "##" : ""
                
                let searchTerm = Substring(prefix + subToken).lowercased()
                
                let subTokenID = QUEVocabulary.tokenID(of: searchTerm)
                
                if subTokenID == QUEVocabulary.unkownTokenID {
                    let nextSubtoken = subToken.dropLast()

                    if nextSubtoken.isEmpty {
                        subTokens = [token]
                        subTokenIDs = [QUEVocabulary.unkownTokenID]
                        
                        break
                    }
                    
                    subToken = nextSubtoken
                } else {
                    foundFirstSubtoken = true
                    
                    subTokens.append(subToken)
                    subTokenIDs.append(subTokenID)
                    
                    subToken = token.suffix(from: subToken.endIndex)
                }
            }
            
            wordpieceTokens += subTokens
            wordpieceTokenIDs += subTokenIDs
        }
        
        guard wordpieceTokens.count == wordpieceTokenIDs.count else {
            fatalError("Tokens array and TokenIDs arrays must be the same size.")
        }
        
        return (wordpieceTokens, wordpieceTokenIDs)
    }
}
