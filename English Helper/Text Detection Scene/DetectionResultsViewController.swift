//
//  DetectionResultsViewController.swift
//  English Helper
//
//  Created by Матвей Анисович on 25.09.2020.
//  Copyright © 2020 Матвей Анисович. All rights reserved.
//

import UIKit

class DetectionResultsViewController: UIViewController, UIScrollViewDelegate {

    var image:UIImage!
    var detections:[TextDetection]!
    var mainVC:MainViewController!
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var viewToDrawOutlines: ScanResultsView!
    @IBAction func addButtonTapped(_ sender: UIButton) {
        var selectedDetections = detections.filter { (detection) -> Bool in
            return detection.isSelected
        }
        
        let mainVCTGroups = mainVC.groups
        
        let actionMenu = UIAlertController(title: "В какую группу сохранить выделенные слова?", message: "", preferredStyle: .actionSheet)
        actionMenu.addAction(.init(title: "Отменить", style: .cancel))
        for groupIndex in 0..<mainVCTGroups.count {
            actionMenu.addAction(UIAlertAction(title: title, style: .default, handler: { (action) in
                for selectionIndex in 0..<selectedDetections.count {
                    if [selectedDetections[selectionIndex].text] != selectedDetections[selectionIndex].text.components(separatedBy: ",") {
                        for word in selectedDetections[selectionIndex].text.components(separatedBy: ",") {
                            let detection = selectedDetections[selectionIndex].copy() as! TextDetection
                            detection.text = word.trimmingCharacters(in: .whitespacesAndNewlines)
                            selectedDetections.append(detection)
                        }
                        selectedDetections.remove(at: selectionIndex)
                    }
                }
                self.translateWords(from: selectedDetections, toGroupIndex: groupIndex)
            }))
        }
        present(actionMenu, animated: true, completion: nil)
        
        // hello, world, lol
    }
    
    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        let touchedDetections = detections!.filter({ (detection) -> Bool in
            return detection.isSelected
        })
        if touchedDetections.count > 0 {
            detections.forEach { (detection) in
                detection.isSelected = false
                viewToDrawOutlines.setNeedsDisplay()
            }
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func translateWords(from detections:[TextDetection], toGroupIndex:Int) {
        let alert = UIAlertController(title: "Перевод слов", message: "Пожалуйста, подождите...", preferredStyle: .alert)
        alert.addActivityIndicator()
        present(alert, animated: true, completion: {
            for detection in detections {
                let newWord = Translator().translate(detection.text)
                self.mainVC.groups[toGroupIndex].words.append(newWord)
            }
            self.mainVC.tableView.reloadData()
            alert.dismiss(animated: true, completion: {
                self.dismiss(animated: true, completion: nil)
            })
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let alert = UIAlertController(title: "Идет обработка фотографии", message: "Пожалуйста, подождите...", preferredStyle: .alert)
        alert.addActivityIndicator()
        self.present(alert, animated: true, completion: {
            self.setup()
            alert.dismiss(animated: true)
        })
    }
    
    func setup() {
        self.imageView.image = self.image
        self.detections = TextDetector().detectTexts(on: self.image, with: .accurate, customImageSize: self.viewToDrawOutlines.frame.size)
        self.viewToDrawOutlines.detections = self.detections
        self.viewToDrawOutlines.imageView = self.imageView
        self.viewToDrawOutlines.setNeedsDisplay()
    }
    
    private func disableDismissalRecognizers() {
        navigationController?.presentationController?.presentedView?.gestureRecognizers?.forEach {
            $0.isEnabled = false
        }
    }
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        viewToDrawOutlines.customScale = scrollView.zoomScale
        viewToDrawOutlines.setNeedsDisplay()
    }
    
}


class ScanResultsView:UIView {
    var detections:[TextDetection]?
    var imageView:UIImageView!
    var customScale:CGFloat = 1.0
    var isErasing = false
    var magnifyView:MagnifyView! = nil
    var touchLoc:CGPoint!
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        if magnifyView != nil {
            var cirlce = UIBezierPath()
            cirlce = UIBezierPath(ovalIn: CGRect(x: touchLoc.x, y: touchLoc.y - 100, width: 5, height: 5))
            UIColor.gray.setFill()
            cirlce.fill()
        }
        
        
        if let detections = detections {
            for detection in detections {
                
                let path = detection.observationPath!.copy() as! UIBezierPath
                
                path.lineWidth = 1
                UIColor.green.set()
                if detection.isSelected {
                    UIColor.systemBlue.setFill()
                    UIColor.systemBlue.set()
                }
                path.stroke(with: .normal, alpha: 0.5)
                path.fill(with: .normal, alpha: 0.2)
                
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        if magnifyView == nil {
            magnifyView = MagnifyView.init(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
            magnifyView.viewToMagnify = self.superview
            magnifyView.setTouchPoint(pt: location)
            self.addSubview(magnifyView)
        }
        
        let touchedDetection = detections!.first(where: { (detection) -> Bool in
            return detection.observationPath.contains(location)
        })
        isErasing = touchedDetection?.isSelected ?? false
        touchLoc = location
        self.setNeedsDisplay()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        let touchedDetection = detections?.first(where: { (detection) -> Bool in
            return detection.observationPath.contains(location)
        })
        if touchedDetection?.isSelected == false && isErasing == false {
            touchedDetection?.isSelected = true
            self.setNeedsDisplay()
        } else if touchedDetection?.isSelected == true && isErasing == true {
            touchedDetection?.isSelected = false
            self.setNeedsDisplay()
        }
        magnifyView.setTouchPoint(pt: location)
        magnifyView.setNeedsDisplay()
        print(touchedDetection ?? "No detection here!")
        touchLoc = location
        self.setNeedsDisplay()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        if magnifyView != nil {
            magnifyView.removeFromSuperview()
            magnifyView = nil
        }
        touchLoc = location
        self.setNeedsDisplay()
    }
}

extension UIAlertController {

    private struct ActivityIndicatorData {
        static var activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
    }

    func addActivityIndicator() {
        let vc = UIViewController()
        vc.preferredContentSize = CGSize(width: 40,height: 40)
        ActivityIndicatorData.activityIndicator.startAnimating()
        vc.view.addSubview(ActivityIndicatorData.activityIndicator)
        self.setValue(vc, forKey: "contentViewController")
    }

    func dismissActivityIndicator() {
        ActivityIndicatorData.activityIndicator.stopAnimating()
        self.dismiss(animated: false)
    }
}
