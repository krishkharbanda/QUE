//
//  QUE.swift
//  FindingAnswers
//
//  Created by Krish Kharbanda on 5/22/21.
//  Copyright © 2021 KK Can Code. All rights reserved.
//

import CoreML
import Foundation
import UIKit

class QUE {
    var queModel: BERTQAFP16 {
        do {
            return try BERTQAFP16(configuration: .init())
        } catch {
            fatalError("Couldn't load QUE model due to: \(error.localizedDescription)")
        }
    }
    func findAnswer(for question: String, in document: String) -> Substring {
        
        let queInput = QUEInput(documentString: document, questionString: question)
        
        guard queInput.totalTokenSize <= QUEInput.maxTokens else {
            var message = "Text and question are too long"
            message += " (\(queInput.totalTokenSize) tokens)"
            message += " for the BERT model's \(QUEInput.maxTokens) token limit."
            return Substring(message)
        }
        
        let modelInput = queInput.modelInput!
        
        guard let prediction = try? queModel.prediction(input: modelInput) else {
            return "The QUE model is unable to make a prediction."
        }
        
        guard let bestLogitIndices = bestLogitsIndices(from: prediction,
                                                       in: queInput.documentRange) else {
            return "Couldn't find a valid answer. Please try again."
        }
        
        let documentTokens = queInput.document.tokens
        let answerStart = documentTokens[bestLogitIndices.start].startIndex
        let answerEnd = documentTokens[bestLogitIndices.end].endIndex
        
        let originalText = queInput.document.original
        return originalText[answerStart..<answerEnd]
    }
}
