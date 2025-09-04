//
//  WordFunctions.swift
//  Hangman
//
//  Created by Ling on 9/1/25.
//

import Foundation

class WordFunctions {
    static let wordfunctions = WordFunctions()
    let mediumPath = Bundle.main.path(forResource: "medium_words", ofType: "txt")
    let longPath = Bundle.main.path(forResource: "long_words", ofType: "txt")
    
    func randomMediumWord() -> String {
        let mediumWords = try! String(contentsOfFile: mediumPath!, encoding: .utf8).split(separator: "\n")
        let randomIndex = Int.random(in: 0..<mediumWords.count)
        let word:String = String(mediumWords[randomIndex]).uppercased()
        return word.validWord()
    }
    
    func randomLongWord() -> String {
        let longWords = try! String(contentsOfFile: longPath!,  encoding: .utf8).split(separator: "\n")
        let randomIndex = Int.random(in: 0..<longWords.count)
        let word:String = String(longWords[randomIndex]).uppercased()
        return word.validWord()
    }
}
extension String {
    func validWord() -> String {
        let regex = "^[a-zA-Z]+$"
        if (self.range(of: regex, options: .regularExpression) == nil) || (self.count > 20) {
            return "-1"
        } else {
            return self
        }
    }
}
