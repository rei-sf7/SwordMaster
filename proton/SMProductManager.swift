//
//  SMProductManager.swift
//  proton
//
//  Created by KakimotoMasaaki on 2016/01/16.
//  Copyright © 2016年 Masaaki Kakimoto. All rights reserved.
//

import Foundation
import StoreKit

private var productManagers : Set<SMProductManager> = Set()

class SMProductManager: NSObject, SKProductsRequestDelegate {
    
    private var completionForProductidentifiers : (([SKProduct]?,NSError?) -> Void)?
    
    /// 課金アイテム情報を取得
    class func productsWithProductIdentifiers(productIdentifiers : [String]!,completion:(([SKProduct]?,NSError?) -> Void)?){
        let productManager = SMProductManager()
        productManager.completionForProductidentifiers = completion
        let productRequest = SKProductsRequest(productIdentifiers: Set(productIdentifiers))
        productRequest.delegate = productManager
        productRequest.start()
        productManagers.insert(productManager)
    }
    
    // MARK: - SKProducts Request Delegate
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        var error : NSError? = nil
        if response.products.count == 0 {
            error = NSError(domain: "ProductsRequestErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey:"プロダクトを取得できませんでした。"])
        }
        completionForProductidentifiers?(response.products, error)
    }
    
    private func request(request: SKRequest, didFailWithError error: NSError) {
        let error = NSError(domain: "ProductsRequestErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey:"プロダクトを取得できませんでした。"])
        completionForProductidentifiers?(nil,error)
        productManagers.remove(self)
    }
    
    func requestDidFinish(_ request: SKRequest) {
        productManagers.remove(self)
    }
    
    // MARK: - Utility
    /// おまけ 価格情報を抽出
    class func priceStringFromProduct(product: SKProduct!) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.formatterBehavior = .behavior10_4
        numberFormatter.numberStyle = .currency
        numberFormatter.locale = product.priceLocale
        return numberFormatter.string(from: product.price)!
    }
    
}
