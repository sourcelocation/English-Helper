//
//  MainViewController.swift
//  English Helper
//
//  Created by Матвей Анисович on 04.09.2020.
//  Copyright © 2020 Матвей Анисович. All rights reserved.
//

import UIKit
import GoogleMobileAds

class MainViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UISearchResultsUpdating, GADRewardedAdDelegate {
    
    // MARK: Variables
    var translator = Translator()
    var groups:[Group] = []
//    var groupTitles:[String] = []
    let textDetector = TextDetector()
    var filteredWords:[Group] = []
    var searchController:UISearchController!
    var avaliableWords:Int {
        get {
            UserDefaults.standard.integer(forKey: "avaliableWords")
        }
        set {
            UserDefaults.standard.set(newValue,forKey: "avaliableWords")
        }
    }
    var freeScansLeft:Int {
        get {
            UserDefaults.standard.integer(forKey: "freeScansLeft")
        }
        set {
            UserDefaults.standard.set(newValue,forKey: "freeScansLeft")
        }
    }
    var rewardedAd: GADRewardedAd?
    
    
    //MARK: IBOutles and IBActions
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func shareButtonClicked(_ sender: UIBarButtonItem) {
        if let str = String(data: UserDefaults.standard.data(forKey: "words")!, encoding: .utf8)  {
            let filename = getDocumentsDirectory().appendingPathComponent("Words.txt")
            do {
                try str.write(toFile: filename, atomically: true, encoding: String.Encoding.utf8)
                let fileURL = NSURL(fileURLWithPath: filename)
                let objectsToShare = [fileURL]
                let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
                self.present(activityVC, animated: true, completion: nil)
            } catch {
                print("cannot write file")
            }
        }
    }
    
    
    @IBAction func addSectionButtonClicked(_ sender: UIBarButtonItem) {
        if self.groups.count >= 2 && UserDefaults.standard.bool(forKey: "premium") == false {
            let alert = UIAlertController(title: "Достигнут лимит групп", message: "Вы не можете создавать больше 2 групп. Купите премиум для обхода этого лимита.", preferredStyle: .alert)
            alert.addAction(.init(title: "Премиум", style: .cancel, handler: { (action) in
                self.showPremiumPage()
            }))
            alert.addAction(.init(title: "ОК", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
        let alert = UIAlertController(title: "Новая группа", message: "Введите имя для новой группы", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Имя"
            textField.delegate = self
        }
        alert.addAction(UIAlertAction(title: "Добавить", style: .default, handler: { (action) in
            if alert.textFields![0].hasText {
                self.groups.insert(Group(words: [], title: alert.textFields![0].text!),at: 0)
                self.saveGroups()
                self.tableView.insertSections([0], with: .fade)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    self.tableView.reloadData()
                }
            } else {
                self.present(alert, animated: true, completion: nil)
            }
        }))
        alert.addAction(.init(title: "Отмена", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    @IBAction func scanButtonTapped(_ sender: UIBarButtonItem) {
        if UserDefaults.standard.bool(forKey: "premium") || freeScansLeft > 0 {
            freeScansLeft -= 1
            
            let imagePickerController = UIImagePickerController()
            imagePickerController.sourceType = .camera
            imagePickerController.allowsEditing = false
            imagePickerController.delegate = self
            present(imagePickerController, animated: true)
        } else {
            showPremiumPage()
        }
        
    }
    @IBAction func editButtonClicked(_ sender: UIBarButtonItem) {
        self.tableView.setEditing(!tableView.isEditing, animated: true)
        sender.style = sender.style == .done ? .plain : .done
        sender.title = tableView.isEditing ? "Готово" : "Править"
        
        self.setEditing(!self.isEditing, animated: true)
        
        for section in 0..<tableView.numberOfSections {
            tableView.beginUpdates()
            let headerView = tableView.headerView(forSection: section)
            let button = headerView?.subviews.first(where: { (subview) -> Bool in
                return subview is UIButton
            })
            button?.translatesAutoresizingMaskIntoConstraints = false
            headerView?.textLabel!.centerYAnchor.constraint(equalTo: button!.centerYAnchor, constant: 0).isActive = true
            headerView?.textLabel!.trailingAnchor.constraint(equalTo: button!.leadingAnchor, constant: -8).isActive = true
            UIView.animate(withDuration: 0.3, animations: {
                button?.alpha = self.tableView.isEditing ? 1 : 0
            })
            tableView.endUpdates()
        }
    }
    
    //MARK: View Life Cycles
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let wordsData = UserDefaults.standard.data(forKey: "words") {
            self.groups = try! JSONDecoder().decode([Group].self, from: wordsData)
        }
        
        let launchedBefore = UserDefaults.standard.bool(forKey: "launchedBefore")
        if launchedBefore  {
            print("Not first launch.")
        } else {
            print("First launch, setting UserDefault.")
            UserDefaults.standard.set(true, forKey: "launchedBefore")
            avaliableWords = 8
            freeScansLeft = 2
            groups.append(Group(words: [], title: "My words"))
        }
        saveGroups()
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        view.addGestureRecognizer(tap)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.refresh), name: NSNotification.Name(rawValue: "newDataNotif"), object: nil)
        
        if UserDefaults.standard.bool(forKey: "premium") {
            searchController = UISearchController(searchResultsController: nil)
            searchController.searchResultsUpdater = self
            searchController.obscuresBackgroundDuringPresentation = false
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = true
            self.avaliableWords = 9999
        } else {
            rewardedAd = GADRewardedAd(adUnitID: "ca-app-pub-6804648379784599/4472196540")
            loadAd()
        }
    }
    
    // MARK: @objc functions
    @objc func refresh() {
        if let wordsData = UserDefaults.standard.data(forKey: "words") {
            self.groups = try! JSONDecoder().decode([Group].self, from: wordsData)
        }
        self.tableView.reloadData()
    }
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
        }
    }
    @objc private func keyboardWillHide(notification: NSNotification) {
        tableView.contentInset = .zero
    }
    
    @objc func textFieldTextChanged(textField: UITextField) {
        let text = textField.text?.lowercased() ?? ""
        textField.frame.size.width = textField.intrinsicContentSize.width > 100 ? textField.intrinsicContentSize.width : 100
        let textFieldText = textField.text
        guard let indexPathOfCell = (textField.superview?.superview as! TableViewCell).getIndexPath() else { return }
        
        DispatchQueue.global(qos: .utility).async {
            if self.groups[indexPathOfCell.section].words.isEmpty {
                return
            }
            let newWord = self.translator.translate(text)
            DispatchQueue.main.async {
                var textFieldTextNow = ""
                textFieldTextNow = textField.text!
                
                if textFieldText != textFieldTextNow { return }
                self.groups[indexPathOfCell.section].words[indexPathOfCell.row] = newWord
                self.groups[indexPathOfCell.section].words[indexPathOfCell.row].word = self.groups[indexPathOfCell.section].words[indexPathOfCell.row].word.firstUppercased
                self.saveGroups()
                
                let word = self.groups[indexPathOfCell.section].words[indexPathOfCell.row]
                
                if self.tableView.cellForRow(at: indexPathOfCell) == nil { return }
                let cell = self.tableView.cellForRow(at: indexPathOfCell) as! TableViewCell
                cell.transcriptionLabel.text = word.transcription
                cell.translationLabel.text = word.translation
            } 
        }
    }
    
    @objc func addButtonClicked(button: UIButton) {
        print(avaliableWords)
        if avaliableWords <= 0 {
            showWordsLimitAlert()
            return
        }
        let section = button.tag
        
        groups[section].words.append(Word(word: "", translation: "", transcription: ""))
        tableView.insertRows(at: [IndexPath(row: groups[section].words.count - 1, section: section)], with: .automatic)
        
        selectNextField(indexPath: IndexPath(row: groups[section].words.count - 1, section: section))
        avaliableWords -= 1
    }
    
    @objc func removeSectionButtonClicked(button: UIButton) {
        let alert = UIAlertController(title: "Вы уверены, что хотите удалить эту группу?", message: "Это действие необратимо. Если Вы хотите на время скрыть группу, то нажмите на её название.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Удалить", style: .destructive, handler: { (action) in
            self.groups.remove(at: button.tag)
            self.tableView.deleteSections([button.tag], with: .automatic)
            self.saveGroups()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.tableView.reloadData()
            }
        }))
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    @objc private func hideSection(gesture: UIGestureRecognizer) {
        let section = gesture.view!.tag
        print(section)
        
        groups[section].isCollapsed.toggle()
        if groups[section].isCollapsed {
            tableView.deleteRows(at: indexPathsForSection(section), with: .fade)
            UIView.animate(withDuration: 0.25, animations: {
                let footer = self.tableView.footerView(forSection: section)!
                let cellView = footer.subviews[2]
                let addButton = cellView.subviews.first!
                addButton.alpha = 0
            })
        } else {
            tableView.insertRows(at: indexPathsForSection(section), with: .fade)
            UIView.animate(withDuration: 0.25, animations: {
                let footer = self.tableView.footerView(forSection: section)!
                let cellView = footer.subviews[2]
                let addButton = cellView.subviews.first!
                addButton.alpha = 1
            })
        }
        saveGroups()
    }
    
    
    
    // MARK: Text Field
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print(avaliableWords)
        if avaliableWords <= 0 {
            showWordsLimitAlert()
            return false
        }
        
        guard let indexPathOfCell = (textField.superview?.superview as? TableViewCell)?.getIndexPath() else { return false }
        var nextIndexPath = IndexPath(row: indexPathOfCell.row + 1, section: indexPathOfCell.section)
        if tableView.cellForRow(at: nextIndexPath) == nil || tableView.cellForRow(at: nextIndexPath) is AddWordTableViewCell {
            groups[indexPathOfCell.section].words.append(Word(word: "", translation: "", transcription: ""))
            tableView.insertRows(at: [IndexPath(row: indexPathOfCell.row + 1, section: indexPathOfCell.section)], with: .automatic)
            nextIndexPath = IndexPath(row: indexPathOfCell.row + 1, section: indexPathOfCell.section)
            self.saveGroups()
        }
        selectNextField(indexPath: indexPathOfCell)
        avaliableWords -= 1
        return false
    }
    
    func selectNextField(indexPath:IndexPath) {
        let nextIndexPath = IndexPath(row: indexPath.row + 1, section: indexPath.section)
        let nextResponder = tableView.cellForRow(at: nextIndexPath)?.viewWithTag(1)
        
        // Fast clicking "next" button can cause crash, so this solution should prevent the app from crashing
        if nextResponder != nil {
            nextResponder!.becomeFirstResponder()
        }
    }
    
    // MARK: Search Bar
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text else { return }
        searchTextDidChange(searchText: text)
    }
    func searchTextDidChange(searchText:String) {
        if searchText.isEmpty {
            filteredWords = []
            tableView.reloadData()
            return
        }
        var newFilteredWords: [Group] = []
        for index in 0..<groups.count {
            let wordsInGroup = groups[index].words
            var filteredWordsinGroup:[Word] = []
            filteredWordsinGroup = wordsInGroup.filter({ (word) -> Bool in
                return word.word.range(of: searchText, options: .caseInsensitive) != nil || word.translation.range(of: searchText, options: .caseInsensitive) != nil
            })
            newFilteredWords.append(Group(words: filteredWordsinGroup, title: groups[index].title))
        }
        filteredWords = newFilteredWords
        print(filteredWords)
        
        tableView.reloadData()
    }
    
    
    // MARK: Ad stuff
    func rewardedAd(_ rewardedAd: GADRewardedAd, userDidEarn reward: GADAdReward) {
        avaliableWords = 15
        print("Reward received with currency: \(reward.type), amount \(reward.amount).")
        loadAd()
    }
    func loadAd() {
        rewardedAd?.load(GADRequest()) { error in
            if let error = error {
                print(error)
            } else {
                // Ad successfully loaded.
            }
        }
    }
    //MARK: Scan Ended
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        guard let image = info[.originalImage] as? UIImage else {
            print("No image found")
            return
        }
        let resultsVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "scanResultsVC") as! DetectionResultsViewController
        resultsVC.image = image
        resultsVC.mainVC = self
        self.present(resultsVC, animated: true, completion: {
            resultsVC.presentationController?.presentedView?.gestureRecognizers?[0].isEnabled = false
        })
    }
    
    //MARK: Other
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.tableView.reloadData()
    }
    
    func getDocumentsDirectory() -> NSString {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory as NSString
    }
    func saveGroups() {
        if let encoded = try? JSONEncoder().encode(self.groups) {
            UserDefaults.standard.set(encoded, forKey: "words")
        }
    }
    func showWordsLimitAlert() {
        let alert = UIAlertController(title: "Чтобы добавить еще одно слово, нужно просмотреть рекламу", message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Продолжить", style: .default, handler: { (action) in
            if self.rewardedAd?.isReady == true {
                self.rewardedAd?.present(fromRootViewController: self, delegate:self)
            }
        }))
        alert.addAction(UIAlertAction(title: "Убрать рекламу", style: .default, handler: { (action) in
            self.showPremiumPage()
        }))
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }
    func showPremiumPage() {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "premiumVC") as! PremiumViewController
        vc.mainVC = self
        present(vc, animated: true, completion: nil)
    }
    func indexPathsForSection(_ section:Int) -> [IndexPath] {
        var indexPaths = [IndexPath]()
        
        for row in 0..<self.groups[section].words.count {
            indexPaths.append(IndexPath(row: row,
                                        section: section))
        }
        
        return indexPaths
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let maxLength = 30
        let currentString: NSString = (textField.text ?? "") as NSString
        let newString: NSString =
            currentString.replacingCharacters(in: range, with: string) as NSString
        return newString.length <= maxLength
    }
}



//MARK: ----- TableView -----
extension MainViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if groups[section].isCollapsed { return 0 }
        
        if !filteredWords.isEmpty, !filteredWords[section].words.isEmpty {
            return filteredWords[section].words.count
        } else if !filteredWords.isEmpty {
            return 0
        }
        if groups.count - 1 >= section {
            return groups[section].words.count
        } else {
            return 1
        }
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return groups[section].title
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return groups.count
    }
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "Удалить") { (action, sourceView, completionHandler) in
            self.groups[indexPath.section].words.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            self.saveGroups()
        }
        let swipeActionConfig = UISwipeActionsConfiguration(actions: [delete])
        swipeActionConfig.performsFirstActionWithFullSwipe = true
        return swipeActionConfig
    }
    
    //MARK: cellForRowAt
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let words = filteredWords.isEmpty ? self.groups : filteredWords
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! TableViewCell
        
        cell.wordTextField.text = words[indexPath.section].words[indexPath.row].word
        cell.wordTextField.tag = 1
        cell.wordTextField.delegate = self
        cell.wordTextField.addTarget(self, action: #selector(textFieldTextChanged(textField:)), for: .editingChanged)
        cell.wordTextField.frame.size.width = cell.wordTextField.intrinsicContentSize.width > 100 ? cell.wordTextField.intrinsicContentSize.width : 100
        
        cell.translationLabel.text = words[indexPath.section].words[indexPath.row].translation
        cell.transcriptionLabel.text = words[indexPath.section].words[indexPath.row].transcription
        return cell
    }
    
    
    //MARK: Header and footer
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionHeaderView = UITableViewHeaderFooterView()
        sectionHeaderView.textLabel?.text = groups[section].title.uppercased()
        sectionHeaderView.textLabel?.sizeToFit()
        sectionHeaderView.tag = section
        
        let gesture = UITapGestureRecognizer(target: self, action:  #selector(self.hideSection(gesture:)))
        sectionHeaderView.addGestureRecognizer(gesture)
        
        let removeButton = UIButton(frame: CGRect(x: (sectionHeaderView.textLabel!.text?.width(withConstrainedHeight: 15, font: .systemFont(ofSize: 13)))! + 16, y: 2.5 + (section == 0 ? 18.0 : 0.0), width: 40, height: 40))
        removeButton.setImage(UIImage(systemName: "minus.circle.fill"), for: [])
        removeButton.tag = section
        removeButton.alpha = tableView.isEditing ? 1 : 0
        removeButton.addTarget(self, action: #selector(self.removeSectionButtonClicked(button:)), for: .touchUpInside)
        sectionHeaderView.addSubview(removeButton)
        
        return sectionHeaderView
    }
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let headerView = UITableViewHeaderFooterView.init(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 70))
        let headerCell = tableView.dequeueReusableCell(withIdentifier: "addCell") as! AddWordTableViewCell
        headerCell.frame = headerView.bounds
        headerCell.button.addTarget(self, action: #selector(addButtonClicked(button:)), for: .touchUpInside)
        headerCell.button.tag = section
        if #available(iOS 13.0, *) {
            headerCell.button.layer.borderColor = UIColor.systemGray5.cgColor
        }
        headerCell.button.layer.borderWidth = self.isDarkMode ? 1.5 : 0
        
        if isDarkMode {
            if #available(iOS 13.0, *) {
                headerCell.button.backgroundColor = UIColor.systemGray5
            }
        } else {
            headerCell.button.backgroundColor = UIColor.white
        }
        headerCell.button.alpha = groups[section].isCollapsed ? 0 : 1
        headerCell.backgroundColor = .clear
        headerView.addSubview(headerCell)
        return headerView
    }
    
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 70
    }
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if groups[proposedDestinationIndexPath.section].isCollapsed {
            return sourceIndexPath
        }
        return proposedDestinationIndexPath
    }
    
    
    //MARK:Moveable cells
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movedObject = self.groups[sourceIndexPath.section].words[sourceIndexPath.row]
        self.groups[sourceIndexPath.section].words.remove(at: sourceIndexPath.row)
        self.groups[destinationIndexPath.section].words.insert(movedObject, at: destinationIndexPath.row)
    }
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    
    
    // MARK: 3D Menu
    @available(iOS 13.0, *)
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        
        if !(self.tableView.cellForRow(at: indexPath) is TableViewCell) { return UIContextMenuConfiguration() }
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: { suggestedActions in
            return self.makeContextMenu(for: indexPath)
        })
    }
    
    @available(iOS 13.0, *)
    func makeContextMenu(for indexPath: IndexPath) -> UIMenu {
        
        let copyAction = UIAction(title: "Скопировать", image: UIImage(systemName:"doc.on.clipboard")) { [weak self] _ in
            guard let self = self else { return }
            let cell = self.tableView.cellForRow(at: indexPath) as! TableViewCell
            let pasteboard = UIPasteboard.general
            pasteboard.string = "\(cell.wordTextField.text ?? "Нет слова"); \(cell.transcriptionLabel.text ?? "Нет транскрипции"); \(cell.translationLabel.text ?? "Нет перевода") "
            
        }
        let shareAction = UIAction(title: "Поделиться",image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
            guard let self = self else { return }
            let cell = self.tableView.cellForRow(at: indexPath) as! TableViewCell
            let textToShare = [ "\(cell.wordTextField.text ?? "Нет слова"); \(cell.transcriptionLabel.text ?? "Нет транскрипции"); \(cell.translationLabel.text ?? "Нет перевода") " ]
            let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
            //avoiding to crash on iPad
            if let popoverController = activityViewController.popoverPresentationController {
                popoverController.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
                popoverController.sourceView = self.view
                popoverController.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
            }
            self.present(activityViewController, animated: true, completion: nil)
        }
        
        // Create and return a UIMenu with the share action
        return UIMenu(title: "", children: [copyAction, shareAction])
    }
    
}



//MARK:Other
extension StringProtocol {
    var firstUppercased: String { prefix(1).uppercased() + dropFirst() }
    var firstCapitalized: String { prefix(1).capitalized + dropFirst() }
}

extension UIViewController {
    var isDarkMode: Bool {
        if #available(iOS 13.0, *) {
            return self.traitCollection.userInterfaceStyle == .dark
        }
        else {
            return false
        }
    }    
}

extension String {
    func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        
        return ceil(boundingBox.width)
    }
}
