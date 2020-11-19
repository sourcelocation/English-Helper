//
//  SettingsViewController.swift
//  English Helper
//
//  Created by Матвей Анисович on 11.09.2020.
//  Copyright © 2020 Матвей Анисович. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController,UIDocumentBrowserViewControllerDelegate {

    @IBOutlet weak var versionLabel: UILabel!
    @IBAction func globalTintValueChanged(_ sender: UISegmentedControl) {
        UIView.animate(withDuration: 0.5, animations: {
            UserDefaults.standard.set(UserDefaults.standard.bool(forKey: "tint"), forKey: "tint")
            self.view.window?.tintColor = sender.selectedSegmentIndex == 0 ? .systemBlue : .systemOrange
        })
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        versionLabel.text = version()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath == IndexPath(row: 0, section: 1) {
            if var str = String(data: UserDefaults.standard.data(forKey: "words")!, encoding: .utf8)  {
                str += "83GroupTitlesA2"
                str += String(data: try! JSONEncoder().encode(UserDefaults.standard.array(forKey: "groupTitles") as! [String]), encoding: .utf8)!
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
    }
    func getDocumentsDirectory() -> NSString {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory as NSString
    }
    func version() -> String {
        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        let build = dictionary["CFBundleVersion"] as! String
        return "\(version) (\(build))"
    }
    
    @available(iOS 11.0, *)
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didImportDocumentAt sourceURL: URL, toDestinationURL destinationURL: URL) {
        let data = try! JSONDecoder().decode([[Word]].self, from: Data(contentsOf: sourceURL))
        print(data)
    }
}

