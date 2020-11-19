//
//  SceneDelegate.swift
//  English Helper
//
//  Created by Матвей Анисович on 04.09.2020.
//  Copyright © 2020 Матвей Анисович. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url {
            print("Import")
            guard url.pathExtension == "txt" else { return }
            
            let _ = url.startAccessingSecurityScopedResource()
            let importedGroups = try! JSONDecoder().decode([Group].self, from: try! Data(contentsOf: url))
            url.stopAccessingSecurityScopedResource()
            
            let actionMenu = UIAlertController(title: "Импорт слов", message: "Выберите какую группу Вы хотите импортировать", preferredStyle: .actionSheet)
            
            actionMenu.addAction(.init(title: "Cancel", style: .cancel))
            
            for index in 0..<importedGroups.count {
                let group = importedGroups[index]
                actionMenu.addAction(.init(title: group.title, style: .default, handler: { (action) in
                    // Кнопка группы нажата
                    let groupToImport = importedGroups[index]
                    if UserDefaults.standard.data(forKey: "words") == nil { return }
                    guard var oldGroups = try? JSONDecoder().decode([Group].self, from: UserDefaults.standard.data(forKey: "words")!) else { return }
                    var oldGroupsTitles:[String] {
                        get {
                            oldGroups.map { $0.title }
                        }
                        set {
                            for index in 0..<oldGroups.count {
                                oldGroups[index].title = newValue[index]
                            }
                        }
                    }
                    
                    if !oldGroupsTitles.contains(groupToImport.title) { oldGroups.append(Group(words: [], title: groupToImport.title)); oldGroupsTitles.append(groupToImport.title)}
                    
                    for indexOfWordToImport in 0..<groupToImport.words.count {
                        let wordToImport = groupToImport.words[indexOfWordToImport]
                        oldGroups[oldGroupsTitles.firstIndex(of: groupToImport.title)!].words.append(wordToImport)
                    }
                    self.saveGroups(oldGroups)
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "newDataNotif"), object: nil)
                    
                }))
            }
            if let popoverController = actionMenu.popoverPresentationController {
                popoverController.sourceView = self.window?.rootViewController?.view //to set the source of your alert
                popoverController.sourceRect = CGRect(x: (self.window?.rootViewController?.view.bounds.midX)!, y: self.window!.rootViewController!.view.bounds.midY, width: 0, height: 0) // you can set this as per your requirement.
                popoverController.permittedArrowDirections = [] //to hide the arrow of any particular direction
            }
            
            self.window?.rootViewController?.present(actionMenu, animated: true)
        }
    }
    func saveGroups(_ groups:[Group]) {
        let encoded = try! JSONEncoder().encode(groups)
        UserDefaults.standard.set(encoded, forKey: "words")
    }
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
    }
    
    private func getText(from string:String, after: String) -> String? {
        if let range = string.range(of: after) {
            let newString = string[range.upperBound...].trimmingCharacters(in: .whitespaces)
            return newString
        }
        return nil
    }
    private func getText(from string:String, before:String) -> String? {
        if let range = string.range(of: before) {
            var newString = string
            newString.removeSubrange(range.lowerBound..<string.endIndex)
            return newString
        }
        
        return nil
    }
}

