//
//  WordModel.swift
//  English Helper
//
//  Created by MacBookPro on 03.10.2020.
//  Copyright © 2020 Матвей Анисович. All rights reserved.
//

import UIKit

class Word:Encodable, Decodable {
    var word:String = ""
    var translation:String!
    var transcription:String!
    var translateMethod:String!
    init(word:String,translation:String,transcription:String) {
        self.word = word
        self.translation = translation
        self.transcription = transcription
    }
}

class Group:Encodable, Decodable {
    var words:[Word] = []
    var title = "My words"
    var isCollapsed = false
    init(words:[Word],title:String) {
        self.words = words
        self.title = title
    }
}

