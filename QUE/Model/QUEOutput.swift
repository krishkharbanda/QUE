//
//  QUEOutput.swift
//  FindingAnswers
//
//  Created by Krish Kharbanda on 5/22/21.
//  Copyright © 2021 KK Can Code. All rights reserved.
//

import CoreML

extension Array where Element: Comparable {

    func indicesOfLargest(_ count: Int = 10) -> [Int] {
        let count = Swift.min(count, self.count)
        let sortedSelf = enumerated().sorted { (arg0, arg1) in arg0.element > arg1.element }
        let topElements = sortedSelf[0..<count]
        let topIndices = topElements.map { (tuple) in tuple.offset }
        return topIndices
    }
}

extension MLMultiArray {

    func doubleArray() -> [Double] {

        let unsafeMutablePointer = dataPointer.bindMemory(to: Double.self, capacity: count)
        let unsafeBufferPointer = UnsafeBufferPointer(start: unsafeMutablePointer, count: count)
        return [Double](unsafeBufferPointer)
    }
}

extension QUE {
    
    func bestLogitsIndices(from prediction: BERTQAFP16Output, in range: Range<Int>) -> (start: Int, end: Int)? {

        let startLogits = prediction.startLogits.doubleArray()
        let endLogits = prediction.endLogits.doubleArray()
        
        let startLogitsOfDoc = [Double](startLogits[range])
        let endLogitsOfDoc = [Double](endLogits[range])
        
        let topStartIndices = startLogitsOfDoc.indicesOfLargest(20)
        let topEndIndices = endLogitsOfDoc.indicesOfLargest(20)
        
        let bestPair = findBestLogitPair(startLogits: startLogitsOfDoc,
                                         bestStartIndices: topStartIndices,
                                         endLogits: endLogitsOfDoc,
                                         bestEndIndices: topEndIndices)
        
        guard bestPair.start >= 0 && bestPair.end >= 0 else {
            return nil
        }
        
        return bestPair
    }

    func findBestLogitPair(startLogits: [Double],
                           bestStartIndices: [Int],
                           endLogits: [Double],
                           bestEndIndices: [Int]) -> (start: Int, end: Int) {
        
        let logitsCount = startLogits.count
        var bestSum = -Double.infinity
        var bestStart = -1
        var bestEnd = -1
                
        for start in 0..<logitsCount where bestStartIndices.contains(start) {
            for end in start..<logitsCount where bestEndIndices.contains(end) {
                let logitSum = startLogits[start] + endLogits[end]
                
                if logitSum > bestSum {
                    bestSum = logitSum
                    bestStart = start
                    bestEnd = end
                }
            }
        }
        return (bestStart, bestEnd)
    }
}
