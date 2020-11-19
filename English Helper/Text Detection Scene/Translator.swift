//
//  Translator.swift
//  English Helper
//
//  Created by Матвей Анисович on 10.09.2020.
//  Copyright © 2020 Матвей Анисович. All rights reserved.
//

import UIKit

class Translator {
    func translate(_ text: String) -> Word {
        let finalWord = Word(word: text, translation: "", transcription: "")
        let wooordHuntWord = translateFromWooordHunt(text)
        finalWord.transcription = wooordHuntWord.transcription
        
        if wooordHuntWord.translateMethod == "word" {
            finalWord.translation = wooordHuntWord.translation
        } else {
            finalWord.translation = translateWithTranslateRu(text).joined(separator: ", ")
            if finalWord.translation.isEmpty {
                finalWord.translation = wooordHuntWord.translation
            }
        }
        
        return finalWord
    }
    
    //MARK: translateFromWooordHunt
    func translateFromWooordHunt(_ text: String) -> Word {
        if text == "" {
            return Word(word: text, translation: "", transcription: "")
        }
        var lowercasedText = text.lowercased()
        if lowercasedText.replacingOccurrences(of: "to ", with: "") != text.lowercased() {
            lowercasedText = lowercasedText.replacingOccurrences(of: "to", with: "")
        }
        
        let myURLString = "https://wooordhunt.ru/word/\(lowercasedText)".trimmingCharacters(in: .whitespacesAndNewlines).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let myURL = URL(string: myURLString)
        var myHTMLString = ""
        do {
            myHTMLString = try String(contentsOf: myURL!, encoding: .utf8)
        } catch let error { print("Error: \(error)") }
        if let transcription = self.getStringsFrom(text: myHTMLString,after:"британская транскрипция слова \(lowercasedText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())\" class=\"transcription\"> ", before: "</span>") {
            //MARK: Просто слово
            
            var translation = self.getStringsFrom(text: myHTMLString,after:"<span class=\"t_inline_en\">", before: "</span>") ?? []
            print(translation)
            
            var translationArray = translation.first?.components(separatedBy: ", ") ?? []
            if translationArray.count != 0 {
                if translation.first != "" {
                    translationArray = Array(translationArray[0..<(translationArray.count < 3 ? translationArray.count : 3)])
                    translation[0] = translationArray.joined(separator: ", ")
                } else {
                    translation[0] = ""
                }
            }
            let word = Word(word: text, translation: translation.first ?? "", transcription: transcription.first ?? "")
            if !myHTMLString.contains("используется как мн.ч. для существительного") {
                word.translateMethod = "word"
            } else {
                word.translateMethod = "other"
            }
            
            return word
        } else if let translation = self.getStringsFrom(text: myHTMLString,after:"<h3>Переведено сервисом «Яндекс.Переводчик»</h3> <div class=\"light_tr\"> ", before: " </div>") {
            //MARK: Словосочетание
            var transcription = ""
            for word in lowercasedText.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "-", with: " ").components(separatedBy: " ") {
                let URLString = "https://wooordhunt.ru/word/\(word)".trimmingCharacters(in: .whitespacesAndNewlines).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
                do {
                    let HTMLString = try String(contentsOf: URL(string: URLString)!, encoding: .utf8)
                    let transcriptionOfWord = self.getStringsFrom(text: HTMLString,after:"британская транскрипция слова \(word.trimmingCharacters(in: .whitespacesAndNewlines))\" class=\"transcription\"> ", before: "</span>")
                    transcription += ((transcriptionOfWord?.first ?? word.trimmingCharacters(in: .whitespacesAndNewlines)) + " ").replacingOccurrences(of: "|", with: "", options: .literal, range: nil)
                } catch let error { print("Error: \(error)") }
            }
            let word = Word(word: text, translation: translation.first!, transcription: "|\(transcription.trimmingCharacters(in: .whitespacesAndNewlines))|")
            word.translateMethod = "yandex"
            return word
        } else if let translation = self.getStringsFrom(text: myHTMLString, after: "<h3>Переведено сервисом «Яндекс.Переводчик»</h3>\r\n\t\t\t<div class=\"light_tr\">\r\n\t\t\t\t", before: "\t\t\t</div>") {
            //MARK: Другое словосочетание
            var transcription = ""
            for word in lowercasedText.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: " ") {
                let URLString = "https://wooordhunt.ru/word/\(word)".trimmingCharacters(in: .whitespacesAndNewlines).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
                do {
                    let HTMLString = try String(contentsOf: URL(string: URLString)!, encoding: .utf8)
                    let transcriptionOfWord = self.getStringsFrom(text: HTMLString,after:"британская транскрипция слова \(word.trimmingCharacters(in: .whitespacesAndNewlines))\" class=\"transcription\"> ", before: "</span>")
                    transcription += ((transcriptionOfWord?.first ?? "") + " ").replacingOccurrences(of: "|", with: "", options: .literal, range: nil)
                } catch let error { print("Error: \(error)") }
            }
            let word = Word(word: text, translation: translation.first!, transcription: "|\(transcription.trimmingCharacters(in: .whitespacesAndNewlines))|")
            word.translateMethod = "yandex"
            return word
            
        } // else if let singularForm = self.getStringsFrom(text: myHTMLString, after: "&ensp;<a href=\"/word/", before: "\"") {
//            //MARK:  Множественное число
//            let transcription = self.getStringsFrom(text: myHTMLString,after:"британская транскрипция слова \(text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))\" class=\"transcription\"> ", before: "</span>")?.first ?? ""
//            var translation = ""
//
//            let URLString = "https://wooordhunt.ru/word/\(singularForm)".trimmingCharacters(in: .whitespacesAndNewlines).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
//            do {
//                let HTMLString = try String(contentsOf: URL(string: URLString)!, encoding: .utf8)
//                translation = self.getStringsFrom(text: HTMLString,after:"<span class=\"t_inline_en\">", before: "</span>")?.first ?? ""
//            } catch let error { print("Error: \(error)") }
//
//
//            var translationArray = (translation ).components(separatedBy: ", ")
//            if translation != "" {
//                translationArray = Array(translationArray[0..<(translationArray.count < 3 ? translationArray.count : 3)])
//                translation = translationArray.joined(separator: ", ")
//            } else {
//                translation = ""
//            }
//            translation += " (Мн.ч.)"
//            let word = Word(word: text, translation: translation, transcription: transcription)
//            word.translateMethod = "word"
//            return word
//        }
        return Word(word: text, translation: "", transcription: "")
    }
    
    //MARK: translateWithTranslateRu
    func translateWithTranslateRu(_ text: String) -> [String] {
        if text == "" {
            return []
        }
        
        let myURLString = "https://www.translate.ru/dictionary/ru-en/\(text.lowercased())".trimmingCharacters(in: .whitespacesAndNewlines).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let myURL = URL(string: myURLString)
        var myHTMLString = ""
        do {
            myHTMLString = try String(contentsOf: myURL!, encoding: .utf8)
        } catch let error { print("Error: \(error)") }
        
        if var translation = self.getStringsFrom(text: myHTMLString,after:"class=\"ref_result\">", before: "</span>") {
            //MARK: Просто слово
            
            var translationArray = (translation.first)!.components(separatedBy: ", ")
            if translation.first != "" {
                translationArray = Array(translationArray[0..<(translationArray.count < 3 ? translationArray.count : 3)])
                translation[0] = translationArray.joined(separator: ", ")
            } else {
                translation[0] = ""
            }
            return translationArray
        } else if var translation = self.getStringsFrom(text: myHTMLString,after:"<span class=\"ref_result\" style=\"color: rgb(103, 103, 103); font-weight: bold;\">", before: "</span>") {
            //MARK: Другое слово
            
            var translationArray = (translation.first)!.components(separatedBy: ", ")
            if translation.first != "" {
                translationArray = Array(translationArray[0..<(translationArray.count < 3 ? translationArray.count : 3)])
                translation[0] = translationArray.joined(separator: ", ")
            } else {
                translation[0] = ""
            }
            return translationArray
        }
        
        // <span class="ref_result" style="color: rgb(103, 103, 103); font-weight: bold;">
        return []
    }
    
    func getStringsFrom(text:String,after:String,before:String) -> [String]? {
        var strings:[String]? = []
        var currentText = text
        
        var foundText = true
        while foundText {
            if let range = currentText.range(of: after) {
                currentText = currentText[range.upperBound...].trimmingCharacters(in: .whitespaces)
                if let range1 = currentText.range(of: before) {
                    var detectedText = currentText
                    detectedText.removeSubrange(range1.lowerBound..<currentText.endIndex)
                    strings!.append(detectedText)
                } else { foundText = false }
            } else { foundText = false }
        }
        return strings!.isEmpty ? nil : strings
    }
}
