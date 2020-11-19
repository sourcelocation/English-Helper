//
//  PremiumViewController.swift
//  English Helper
//
//  Created by Матвей Анисович on 29.09.2020.
//  Copyright © 2020 Матвей Анисович. All rights reserved.
//

import UIKit
import SwiftyStoreKit

class PremiumViewController: UIViewController {
    
    var mainVC:MainViewController!

    @IBOutlet weak var buyButton: ButtonWithShadow!
    @IBAction func buyButtonClicked(_ sender: ButtonWithShadow) {
        SwiftyStoreKit.purchaseProduct("com.exerhythm.EnglishHelper.premium", quantity: 1, atomically: true) { result in
            switch result {
            case .success(let purchase):
                print("Purchase Success: \(purchase.productId)")
                UserDefaults.standard.set(true,forKey: "premium")
                self.dismiss(animated: true, completion: nil)
                self.mainVC.avaliableWords = 9999
                
                let searchController = UISearchController(searchResultsController: nil)
                searchController.searchResultsUpdater = self.mainVC
                searchController.obscuresBackgroundDuringPresentation = false
                self.mainVC.navigationItem.searchController = searchController
                self.mainVC.navigationItem.hidesSearchBarWhenScrolling = true
            case .error(let error):
                switch error.code {
                case .unknown: print("Unknown error. Please contact support")
                case .clientInvalid: print("Not allowed to make the payment")
                case .paymentCancelled: break
                case .paymentInvalid: print("The purchase identifier was invalid")
                case .paymentNotAllowed: print("The device is not allowed to make the payment")
                case .storeProductNotAvailable: print("The product is not available in the current storefront")
                case .cloudServicePermissionDenied: print("Access to cloud service information is not allowed")
                case .cloudServiceNetworkConnectionFailed: print("Could not connect to the network")
                case .cloudServiceRevoked: print("User has revoked permission to use this cloud service")
                default: print((error as NSError).localizedDescription)
                }
            }
        }
    }
    @IBAction func restorePurchase(_ sender: UIButton) {
        SwiftyStoreKit.restorePurchases(atomically: true) { results in
            if results.restoreFailedPurchases.count > 0 {
                print("Restore Failed: \(results.restoreFailedPurchases)")
            } else if results.restoredPurchases.count > 0 {
                print("Restore Success: \(results.restoredPurchases)")
                for result in results.restoredPurchases {
                    if result.productId == "com.exerhythm.EnglishHelper.premium" {
                        UserDefaults.standard.set(true,forKey: "premium")
                        self.dismiss(animated: true, completion: nil)
                        self.mainVC.avaliableWords = 9999
                        
                        let searchController = UISearchController(searchResultsController: nil)
                        searchController.searchResultsUpdater = self.mainVC
                        searchController.obscuresBackgroundDuringPresentation = false
                        self.mainVC.navigationItem.searchController = searchController
                        self.mainVC.navigationItem.hidesSearchBarWhenScrolling = true
                    }
                }
            } else {
                print("Nothing to Restore")
            }
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SwiftyStoreKit.retrieveProductsInfo(["com.exerhythm.EnglishHelper.premium"]) { result in
            if let product = result.retrievedProducts.first {
                let priceString = product.localizedPrice!
                print("Product: \(product.localizedDescription), price: \(priceString)")
                
                DispatchQueue.main.async {
                    self.buyButton.isEnabled = true
                    self.buyButton.setTitle(priceString, for: [])
                }
                
            }
            else if let invalidProductId = result.invalidProductIDs.first {
                print("Invalid product identifier: \(invalidProductId)")
            }
            else {
                print("Error: \(String(describing: result.error))")
            }
        }
    }
}
