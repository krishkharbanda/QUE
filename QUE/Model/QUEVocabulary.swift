//
//  QUEVocabulary.swift
//  FindingAnswers
//
//  Created by Krish Kharbanda on 5/22/21.
//  Copyright © 2021 KK Can Code. All rights reserved.
//

import Foundation

struct QUEVocabulary {
    static let unkownTokenID = lookupDictionary["[UNK]"]!
    static let paddingTokenID = lookupDictionary["[PAD]"]!
    static let separatorTokenID = lookupDictionary["[SEP]"]!
    static let classifyStartTokenID = lookupDictionary["[CLS]"]!

    static func tokenID(of string: String) -> Int {
        let token = Substring(string)
        return tokenID(of: token)
    }

    static func tokenID(of token: Substring) -> Int {
        let unkownTokenID = QUEVocabulary.unkownTokenID
        return QUEVocabulary.lookupDictionary[token] ?? unkownTokenID
    }

    private init() { }
    private static let lookupDictionary = loadVocabulary()

    private static func loadVocabulary() -> [Substring: Int] {
        let fileName = "bert-base-uncased-vocab"
        let expectedVocabularySize = 30_522
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "txt") else {
            fatalError("Vocabulary file is missing")
        }
        
        guard let rawVocabulary = try? String(contentsOf: url) else {
            fatalError("Vocabulary file has no contents.")
        }
        
        let words = rawVocabulary.split(separator: "\n")
        
        guard words.count == expectedVocabularySize else {
            fatalError("Vocabulary file is not the correct size.")
        }
        
        guard words.first! == "[PAD]" && words.last! == "##～" else {
            fatalError("Vocabulary file contents appear to be incorrect.")
        }

        let values = 0..<words.count
        
        let vocabulary = Dictionary(uniqueKeysWithValues: zip(words, values))
        return vocabulary
    }
}
