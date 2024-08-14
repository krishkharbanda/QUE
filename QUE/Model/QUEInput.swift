//
//  QUEInput.swift
//  FindingAnswers
//
//  Created by Krish Kharbanda on 5/22/21.
//  Copyright © 2021 KK Can Code. All rights reserved.
//

import CoreML

struct QUEInput {
    static let maxTokens = 384
    
    static private let documentTokenOverhead = 2
    
    static private let totalTokenOverhead = 3

    var modelInput: BERTQAFP16Input?

    let question: TokenizedString
    let document: TokenizedString

    private let documentOffset: Int

    var documentRange: Range<Int> {
        return documentOffset..<documentOffset + document.tokens.count
    }
    
    var totalTokenSize: Int {
        return QUEInput.totalTokenOverhead + document.tokens.count + question.tokens.count
    }
    
    init(documentString: String, questionString: String) {
        document = TokenizedString(documentString)
        question = TokenizedString(questionString)

        documentOffset = QUEInput.documentTokenOverhead + question.tokens.count
        
        guard totalTokenSize < QUEInput.maxTokens else {
            return
        }
        
        var wordIDs = [QUEVocabulary.classifyStartTokenID]
        
        wordIDs += question.tokenIDs
        wordIDs += [QUEVocabulary.separatorTokenID]
        
        wordIDs += document.tokenIDs
        wordIDs += [QUEVocabulary.separatorTokenID]
        
        let tokenIDPadding = QUEInput.maxTokens - wordIDs.count
        wordIDs += Array(repeating: QUEVocabulary.paddingTokenID, count: tokenIDPadding)

        guard wordIDs.count == QUEInput.maxTokens else {
            fatalError("`wordIDs` array size isn't the right size.")
        }

        var wordTypes = Array(repeating: 0, count: documentOffset)
        
        wordTypes += Array(repeating: 1, count: document.tokens.count)
        
        let tokenTypePadding = QUEInput.maxTokens - wordTypes.count
        wordTypes += Array(repeating: 0, count: tokenTypePadding)

        guard wordTypes.count == QUEInput.maxTokens else {
            fatalError("`wordTypes` array size isn't the right size.")
        }

        let tokenIDMultiArray = try? MLMultiArray(wordIDs)
        let wordTypesMultiArray = try? MLMultiArray(wordTypes)
        
        guard let tokenIDInput = tokenIDMultiArray else {
            fatalError("Couldn't create wordID MLMultiArray input")
        }
        
        guard let tokenTypeInput = wordTypesMultiArray else {
            fatalError("Couldn't create wordType MLMultiArray input")
        }

        let modelInput = BERTQAFP16Input(wordIDs: tokenIDInput,
                                         wordTypes: tokenTypeInput)
        self.modelInput = modelInput
    }
}
