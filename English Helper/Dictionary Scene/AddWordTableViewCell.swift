//
//  AddWordTableViewCell.swift
//  English Helper
//
//  Created by Матвей Анисович on 05.09.2020.
//  Copyright © 2020 Матвей Анисович. All rights reserved.
//

import UIKit

class AddWordTableViewCell: UITableViewCell {
    @IBOutlet weak var button: AddButton!
    
    func getIndexPath() -> IndexPath? {
        guard let superView = self.superview as? UITableView else {
            print("superview is not a UITableView - getIndexPath")
            return nil
        }
        let indexPath = superView.indexPath(for: self)
        return indexPath
    }
    
}
class AddButton:ButtonWithShadow {
    override open var isHighlighted: Bool {
        didSet {
            var defaultColor = UIColor.white
            if isDarkMode {
                if #available(iOS 13.0, *) {
                    defaultColor = UIColor.systemGray5
                    backgroundColor = isHighlighted ? UIColor.systemGray6 : defaultColor
                }
            } else {
                backgroundColor = isHighlighted ? UIColor.lightGray : defaultColor
            }
        }
    }
}
