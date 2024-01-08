//
//  GameViewController.swift
//  proton
//
//  Created by KakimotoMasaaki on 2015/07/07.
//  Copyright (c) 2015年 Masaaki Kakimoto. All rights reserved.
//

import UIKit
import SpriteKit
import Social
import StoreKit

class GameViewController: UIViewController, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    //var audioPlayer:AVAudioPlayer?
    let itunesURL:String = "itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=1029281903"
    
    //ショップが起動できる状態かどうか？
    var isShopEnabled = false
    weak var shopDelegate: GameShopScene? = nil
    static let PLAYCOUNT_UDKEY = "playcount"
    
    // 課金アイテム
    let productID1 = "com.karamage.proton.swordAdd" //剣＋２
    static let SWORDS_UDKEY = "swords"
    static let ADD_SWORDS_PLUS2_UDKEY = "addswordsplus2"
    let products: NSMutableArray = NSMutableArray()
    let uds = UserDefaults.standard

    override func viewDidAppear(_ animated: Bool) {
        openReview()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        let ud = UserDefaults.standard
        let swords = ud.integer(forKey: GameViewController.SWORDS_UDKEY)
        print("swords=\(swords)")
        
        let aproductIdentifiers = [productID1]
        
        //iPadの場合倍率
        print("---self.frame height \(self.view.frame.height)")
        if self.view.frame.height >= 1024 {
            SMStage.base = 1.3
        }
        
        //課金アイテムの処理
        if(SKPaymentQueue.canMakePayments()) {
            //let request: SKProductsRequest = SKProductsRequest(productIdentifiers: Set(productID1))
            let productIdentifiers: NSSet = NSSet(array: aproductIdentifiers) // NSset might need to be mutable
            let request : SKProductsRequest = SKProductsRequest(productIdentifiers: productIdentifiers as! Set<String>)
            request.delegate = self
            request.start()
            print("in App Purchase available")
        } else {
            NSLog("In App Purchaseが有効になっていません")
        }
        
        //ソーシャルボタン表示用のオブザーバー登録
        NotificationCenter.default.addObserver(self, selector: #selector(showSocialShare(_:)), name: NSNotification.Name("socialShare"), object: nil)

        //タイトル画面表示
        let scene = GameTitleScene()
        
        // Configure the view.
        let skView = self.view as! SKView
        if debugflg {
            skView.showsFPS = true
            skView.showsNodeCount = true
        } else {
            skView.showsFPS = false
            skView.showsNodeCount = false
        }
        
        /* Sprite Kit applies additional optimizations to improve rendering performance */
        skView.ignoresSiblingOrder = true
        
        /* Set the scale mode to scale to fit the window */
        scene.scaleMode = .aspectFill
        scene.size = skView.frame.size
        
        scene.vc = self
        
        skView.presentScene(scene)
    }
    
    //レストア開始
    func restoreStart() {
        SKPaymentQueue.default().add(self)
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    // 課金アイテムの情報をサーバから取得
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        
        print("productsRequest didREceiveResponse products.count=\(response.products.count) invalid.count \(response.invalidProductIdentifiers.count)")
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        for product in response.products {
            products.add(product)
            isShopEnabled = true
            nf.locale = product.priceLocale
            print("add product title=\(product.localizedTitle) description=" + product.description + " price=\(String(describing: nf.string(from: product.price)))")
        }
        for invalid in response.invalidProductIdentifiers {
            print("invalid=" + invalid)
        }
    }
    func buyAddSwords(product:SKProduct) {
        print("buyAddSwords")
        let pay = SKPayment(product: product)
        SKPaymentQueue.default().add(self)
        SKPaymentQueue.default().add(pay as SKPayment)
    }
    
    func addSwords() {
        let ud = UserDefaults.standard
        let isbuy = ud.integer(forKey: GameViewController.ADD_SWORDS_PLUS2_UDKEY)
        if isbuy == 0 {
            let swords = ud.integer(forKey: GameViewController.SWORDS_UDKEY)
            ud.setValue(swords + 2, forKey: GameViewController.SWORDS_UDKEY)
            ud.setValue(1, forKey: GameViewController.ADD_SWORDS_PLUS2_UDKEY)
            ud.synchronize()
        }
    }
    
    // 課金リストア処理完了
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        for transaction in queue.transactions {
            switch transaction.payment.productIdentifier{
            case productID1:
                print("リストアトランザクション完了")
                addSwords()
                shopDelegate?.buyLabel1.text = "購入完了"
            default:
                print("In App Purchaseが設定されていません")
            }
        }
        shopDelegate?.restoreLabel1.text = "復元完了"
    }
    
    //購入処理完了
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            let trans: SKPaymentTransaction = transaction
            
            if let error = trans.error {
                print(error)
            }
            
            switch trans.transactionState {
                
            case .purchased:
                
                switch trans.payment.productIdentifier {
                case productID1:
                    print("buyAddSwords")
                    addSwords()
                    shopDelegate?.buyLabel1.text = "購入完了"
                    break
                default:
                    print("In App Purchaseが設定されていません")
                }
                
                queue.finishTransaction(trans)
                break;
            case .failed:
                queue.finishTransaction(trans)
                break;
            default:
                break;
                
            }
        }
    }
    
    func finishTransaction(trans:SKPaymentTransaction)
    {
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
        SKPaymentQueue.default().remove(self)
    }
    
    //ソーシャルボタンの表示
    @objc func showSocialShare(_ notification: NSNotification) {
        
        // (1) オブザーバーから渡ってきたuserInfoから必要なデータを取得する
        let userInfo:Dictionary<String,NSData?> = notification.userInfo as! Dictionary<String,NSData?>
        let message = NSString(data: userInfo["message"]!! as Data, encoding: UInt())
        let social = NSString(data: userInfo["social"]!! as Data, encoding: UInt())
        
        // (2) userInfoの情報をもとにTwitter/Facebookボタンどちらが押されたのか特定する
        var activityType: UIActivity.ActivityType? = nil
        if social == "twitter" {
            activityType = .postToTwitter
        } else if social == "facebook" {
            activityType = .postToFacebook
        }
        
        // (3) shareViewControllerを作成、表示する
        let shareView = UIActivityViewController(activityItems: [message!], applicationActivities: nil)
        shareView.excludedActivityTypes = [UIActivity.ActivityType.addToReadingList]
        
        // TwitterとFacebookが選択されている場合、対応するアクティビティを強制的に選択
        if let activityType = activityType {
            shareView.setValue(message, forKey: "subject")
            shareView.excludedActivityTypes = nil
            shareView.completionWithItemsHandler = { (_, _, _, _) in
                // 完了時の処理
            }
            shareView.setValue(activityType, forKey: "activityType")
        }

        self.present(shareView, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.allButUpsideDown
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func setScreenShot() {
        UIGraphicsBeginImageContextWithOptions(UIScreen.main.bounds.size, false, 0);
        self.view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        screenShot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    func openReview() {
        let playcount = uds.integer(forKey: GameViewController.PLAYCOUNT_UDKEY)
        if playcount == 0 {
            return
        }
        if !uds.bool(forKey: "reviewed") {
            if #available(iOS 8.0, *) {
                let alertController = UIAlertController(
                    title: "ゆうすけからのおねがい",
                    message: "いつもプレイありがとうございます。よろしければレビューを書いて頂けませんか？今後の開発の参考にいたします",
                    preferredStyle: .alert)
                let reviewAction = UIAlertAction(title: "レビューする", style: .default) {
                    action in
                    if let url = URL(string: self.itunesURL), UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        self.uds.set(true, forKey: "reviewed")
                        self.uds.synchronize()
                    }
                }
                let yetAction = UIAlertAction(title: "あとでレビューする", style: .default) {
                    action in
                    self.uds.set(false, forKey: "reviewed")
                    self.uds.synchronize()
                }
                let neverAction = UIAlertAction(title: "今後レビューしない", style: .cancel) {
                    action in
                    self.uds.set(true, forKey: "reviewed")
                    self.uds.synchronize()
                }
                alertController.addAction(reviewAction)
                alertController.addAction(yetAction)
                alertController.addAction(neverAction)
                present(alertController, animated: true, completion: nil)
            } else {
                // Fallback on earlier versions
            }
            
        }
    }
}
