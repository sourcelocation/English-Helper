//
//  TableViewCell.swift
//  English Helper
//
//  Created by Матвей Анисович on 04.09.2020.
//  Copyright © 2020 Матвей Анисович. All rights reserved.
//

import UIKit

class TableViewCell: UITableViewCell {

    @IBOutlet weak var wordTextField: UITextField!
    @IBOutlet weak var transcriptionLabel: UILabel!
    @IBOutlet weak var translationLabel: UILabel!
    
    func getIndexPath() -> IndexPath? {
        guard let superView = self.superview as? UITableView else {
            print("superview is not a UITableView - getIndexPath")
            return nil
        }
        let indexPath = superView.indexPath(for: self)
        return indexPath
    }

}

