//
//  SMPlayer.swift
//  proton
//
//  Created by KakimotoMasaaki on 2015/07/10.
//  Copyright (c) 2015年 Masaaki Kakimoto. All rights reserved.
//

import Foundation
import SpriteKit

//自機ノード管理クラス
class SMPlayerNode: SKSpriteNode {
    //装備している剣の種類
    var swordType: SwordType = SwordType.EXCALIBUR
    //剣の最大値
    var swordMaxNum: Int = 3
    //剣の残りの弾
    var swordNum: Int = 3
    //剣のアイコンの配列
    var swordIcons: [SKSpriteNode] = [SKSpriteNode]()
    //ハートのアイコンの配列
    var heartIcons: [SKSpriteNode] = [SKSpriteNode]()
    
    //被弾できるヒットポイント
    var hitpoint: Int = 3
    
    //自機のスピード
    var speedup: Int = 1
    
    //剣の攻撃力
    var swordPower: Int = 1
    
    //剣のチャージ速度
    var swordCharge: Int = 0
    
    let SPEED_MAX = 10
    let SWORD_NUM_MUX = 15
    let SWORD_CHARGE_MAX = 10
    let HEART_MAX = 15
    
    //アニメーション用ノード
    var hane: SKSpriteNode!
    var warp: SKSpriteNode!
    var dead: SKSpriteNode!
    var haneAim: [SKTexture]!
    var haneAim1: [SKTexture]!
    var haneAim2: [SKTexture]!
    var warpAim: [SKTexture]!
    var warpAim2: [SKTexture]!
    
    //アイテムを取得した時の処理
    func contactItem(item: SMItemNode) {
        item.physicsBody?.categoryBitMask = ColliderType.None
        bgNode.run(kakinSound)
        switch item.type {
        case .COIN:
            totalScore += 100
            scoreLabel.text = "\(totalScore)"
        case .DAIYA:
            bgNode.run(itemgetSound)
            bgNode.run(itemgetSound)
            bgNode.run(itemgetSound)
            totalScore += 1000
            scoreLabel.text = "\(totalScore)"
        case .SWORDNUMUP:
            if self.swordMaxNum < SWORD_NUM_MUX {
                self.swordMaxNum += 1
                self.countUpSword()
                powerupCutin()
            }
        case .SWORDPOWERUP:
            self.swordPower += 1
            powerupCutin()
        case .SWORDCHARGEUP:
            if self.swordCharge < SWORD_CHARGE_MAX {
                self.swordCharge += 1
                powerupCutin()
            }
        case .SPEEDUP:
            if self.speedup < SPEED_MAX {
                self.speedUp()
                powerupCutin()
            }
        case .HEART:
            if self.hitpoint < HEART_MAX {
                //ハート回復
                self.heartUp()
                powerupCutin()
            }
        case .SHIELD:
            self.`guard`()
            powerupCutin()
        case .GOLDSHIELD:
            self.guardGold()
            powerupCutin()
        default:
            break
        }
        item.removeFromParent()
        SMNodeUtil.makeParticleNode(position: CGPoint(x: self.position.x, y: self.position.y + 30), filename: "MyParticle.sks", node: bgNode)
    }
    
    func powerupCutin() {
        let scene = self.scene as! GameScene
        makeWarpAnim()
        bgNode.run(powerupSound)
        bgNode.run(powerupSound)
        bgNode.run(powerupSound)
        scene.cutin()
    }
    
    //バリアの作成
    func `guard`() {
        let `guard` = SMGuardNode2(texture: guard2Texture, location: CGPoint(x:self.position.x + 10, y:100.0), parentnode: bgNode)
        `guard`.makeGuard()
    }
    //バリアの作成
    func guardGold() {
        let `guard` = SMGuardNode2(texture: guard2Texture, location: CGPoint(x:self.position.x + 10, y:100.0), parentnode: bgNode)
        `guard`.makeGuardGold()
    }
    //スピードアップの処理
    func speedUp() {
        self.speedup += 1
        let scaleAction = SKAction.scale(by: 1.05, duration: 0.5)
        hane.run(scaleAction)
    }
    
    //ハート回復アイテムゲット
    func heartUp() {
        makeHeartIcon(index: hitpoint)
        hitpoint += 1
        if self.hitpoint >= 2 {
            self.colorBlendFactor = 0
            self.hane.colorBlendFactor = 0
        }
    }
    
    //相手の弾を被弾したときの処理
    func damegedEnegy(enegy: SMEnegyNode) {
        enegy.physicsBody?.categoryBitMask = ColliderType.None
        countDownHeart()
        SMNodeUtil.fadeRemoveNode(removenode: enegy)
        
        //bgNode.color = UIColor.yellowColor()
        //self.colorBlendFactor = 0.9
        weak var stage: SMStage? = stageManager.currentStage
        if stage != nil {
            stage!.background.color = UIColor.red
            stage!.background.colorBlendFactor = 0.5
            let custumAction = SKAction.customAction(withDuration: 0.0, actionBlock: { (node: SKNode, elapsedTime: CGFloat) -> Void in
                weak var stagetmp: SMStage? = stageManager.currentStage
                if stagetmp != nil {
                    stagetmp!.background.colorBlendFactor = 0.0
                }
            })
            let waitAction = SKAction.wait(forDuration: 0.5)
            bgNode.run(SKAction.sequence([waitAction,custumAction]))
        }
            
        //やられた効果音再生
        bgNode.run(explodeSound)
        bgNode.run(explodeSound)
        
        //やられたアニメーション作成
        SMNodeUtil.makeParticleNode(position: self.position, filename: "deadParticle.sks", hide: true, node: bgNode)
        SMNodeUtil.makeParticleNode(position: self.position, filename: "deadParticle.sks", hide: true, node: bgNode)
        SMNodeUtil.makeParticleNode(position: self.position, filename: "deadParticle.sks", hide: true, node: bgNode)
        bgNode.run(hawawaSound)
        bgNode.run(hawawaSound)
        bgNode.run(hawawaSound)
        if self.hitpoint <= 2 {
            self.color = UIColor.red
            self.colorBlendFactor = 0.5
            self.hane.color = UIColor.red
            self.hane.colorBlendFactor = 0.3
        }
    }
    
    //プレイヤーが死んだ時の処理
    func deadPlayer() {
        //剣やハートのアイコン削除
        statusNode.removeFromParent()
        
        //やられた効果音再生
        bgNode.run(explodeSound)
        bgNode.run(explodeSound)
        bgNode.run(explodeSound)
        
        //やられたアニメーション作成
        SMNodeUtil.makeParticleNode(position: self.position, filename: "deadParticle.sks", hide: true, node: bgNode)
        SMNodeUtil.makeParticleNode(position: self.position, filename: "deadParticle.sks", hide: true, node: bgNode)
        SMNodeUtil.makeParticleNode(position: self.position, filename: "deadParticle.sks", hide: true, node: bgNode)
        SMNodeUtil.makeParticleNode(position: self.position, filename: "deadParticle.sks", hide: true, node: bgNode)
        
        //プレイヤー削除
        SMNodeUtil.fadeRemoveNode(removenode: self)
    }
    
    //プレイヤー作成
    func makePlayer(node: SKNode, textures: [SKTexture]) {
        if debugflg {
            // デバッグモード
            self.swordMaxNum = 10
            self.swordNum = 10
        } else {
            let ud = UserDefaults.standard
            let swords = ud.integer(forKey: GameViewController.SWORDS_UDKEY)
            self.swordMaxNum = swords
            self.swordNum = swords
        }
        //self.blendMode = SKBlendMode.Add
        //self.alpha = 0.9
        self.position = CGPoint(x: node.frame.size.width * 0.5, y: 0)
        //self.colorBlendFactor = 1.0
        //self.color = SKColor(red: 1.0, green: 0, blue: 0, alpha: 1.0)
        
        //物理シミュレーション設定
        /*
        if #available(iOS 8.0, *) {
            self.physicsBody = SKPhysicsBody(texture: self.texture!, size: self.texture!.size())
        } else {
            // Fallback on earlier versions
            self.physicsBody = SKPhysicsBody(rectangleOfSize: texture!.size())
        }*/
        self.physicsBody = SKPhysicsBody(circleOfRadius: 10)
        self.physicsBody?.isDynamic = false
        self.physicsBody?.allowsRotation = false
        self.physicsBody?.categoryBitMask = ColliderType.Player
        //self.physicsBody?.collisionBitMask = ColliderType.Enemy | ColliderType.Enegy
        self.physicsBody?.contactTestBitMask = ColliderType.Enemy | ColliderType.Enegy
        
        node.addChild(self)
        self.zPosition = 2
        
        //画面下から登場
        playerStart(textures: textures)
        
        //パーティクル作成
        let particlePosition = CGPoint(x: 0, y: 25)
        SMNodeUtil.makeParticleNode(position: particlePosition, filename:"playerParticle.sks", hide:false, node:self)
        
        //アニメーション作成
        makePlayerAnimation()
        
        //剣のアイコンを作成
        makeSwordIcon()
        
        //ハートのアイコンを作成
        makeHeartIcon()
    }
    
    //プレイヤー登場のアニメーション
    func playerStart(textures: [SKTexture]) {
        self.removeAllActions()
        
        //パラパラアニメーション
        let paraAction = SKAction.animate(with: textures, timePerFrame: 0.2)
        let repeatParaAction = SKAction.repeatForever(paraAction)
        self.run(repeatParaAction)
        
        //画面下から登場
        let resetAction = SKAction.moveTo(y: 0, duration: 0)
        let playerAction = SKAction.moveTo(y: 50, duration: 2)
        let repeatAction = SKAction.repeatForever(SKAction.sequence([SKAction.moveTo(y: 45, duration: 2),SKAction.moveTo(y: 55, duration: 2)]))
        self.run(SKAction.sequence([resetAction, playerAction, repeatAction]))
        
        let scaleAction1 = SKAction.scale(to: 1.1, duration: 2)
        let scaleAction2 = SKAction.scale(to: 1.0, duration: 2)
        let scaleAction3 = SKAction.scale(to: 0.9, duration: 2)
        let scaleRepeat = SKAction.repeatForever(SKAction.sequence([scaleAction1,scaleAction2,scaleAction3]))
        self.run(scaleRepeat)
    }
    
    //ハートのアイコンを作成
    func makeHeartIcon() {
        for i in 0..<self.hitpoint {
            makeHeartIcon(index: i)
        }
    }
    func makeHeartIcon(index: Int) {
        let icon = SKSpriteNode(texture: heartIconTexture)
        let width:CGFloat! = icon.texture?.size().width
        icon.blendMode = SKBlendMode.add
        icon.alpha = 0.9
        icon.position = CGPoint(x: width * CGFloat(index), y:CGFloat(20.0))
        heartIcons.append(icon)
        statusNode.addChild(icon)
    }
    //ハートをカウントダウン
    func countDownHeart() {
        hitpoint -= 1
        heartIcons[hitpoint].removeFromParent()
        heartIcons.remove(at: hitpoint)
    }
    
    //剣のアイコンを作成
    func makeSwordIcon() {
        for i in 0..<swordMaxNum {
            makeSwordIcon(index: i)
        }
    }
    func makeSwordIcon(index: Int) {
        let icon = SKSpriteNode(texture: swordIconTexture)
        let width:CGFloat! = icon.texture?.size().width
        icon.blendMode = SKBlendMode.add
        icon.alpha = 0.9
        icon.position = CGPoint(x: width * CGFloat(index), y:CGFloat(0.0))
        swordIcons.append(icon)
        statusNode.addChild(icon)
    }
    
    //剣をカウントダウン
    func countDownSword() {
        swordNum -= 1
        swordIcons[swordNum].removeFromParent()
        swordIcons.remove(at: swordNum)
    }
    
    //剣をカウントアップ
    func countUpSword() {
        makeSwordIcon(index: swordNum)
        swordNum += 1
    }
    
    //プレイヤーのアニメーションを作成する
    func makePlayerAnimation() {
        //羽のアニメーションを切り出す
        haneAim = SMAnimationUtil.explodeAnime(imageName: "wing", xFrame: 5, yFrame: 6)
        haneAim1 = [SKTexture](haneAim[3...6])
        haneAim2 = [SKTexture](haneAim[7...22])
        //ワープのアニメーションを切り出す
        warpAim = SMAnimationUtil.explodeAnime(imageName: "warp", xFrame: 2, yFrame: 13)
        warpAim2 = [SKTexture](warpAim[0...14])
        
        //羽のアニメーションを作成
        hane = SKSpriteNode(texture: haneAim[0], size: haneAim[0].size())
        //hane.blendMode = SKBlendMode.Add
        hane.alpha = 0.9
        
        //羽に影を付ける
        if #available(iOS 8.0, *) {
            hane.shadowCastBitMask = 1
        } else {
            // Fallback on earlier versions
        }
        
        self.addChild(hane!)
        makeHaneAnim()
        let scaleHaneAction = SKAction.scale(to: 0.5, duration: 3.0)
        hane.run(scaleHaneAction)
        
        //ワープのアニメーションを作成
        warp = SKSpriteNode(texture: warpAim[0], size: warpAim[0].size())
        warp.blendMode = SKBlendMode.add
        warp.alpha = 0.8
        makeWarpAnim()
    }
    
    func makeHaneAnim() {
        hane.removeAllActions()
        
        let haneAnimAction = SKAction.animate(with: haneAim, timePerFrame: 0.1, resize:false, restore:true)
        let haneAnimAction1 = SKAction.animate(with: haneAim1, timePerFrame: 0.1, resize:false, restore:true)
        let haneAnimAction2 = SKAction.animate(with: haneAim2, timePerFrame: 0.1, resize:false, restore:true)
        let repeatHaneAction = SKAction.repeatForever(haneAnimAction2)
        hane.run(SKAction.sequence([haneAnimAction,haneAnimAction1, repeatHaneAction]))
    }
    
    func makeWarpAnim() {
        warp.removeFromParent()
        self.addChild(warp!)
        warp.removeAllActions()
        let warpAnimAction = SKAction.animate(with: warpAim2, timePerFrame: 0.1, resize:false, restore:true)
        let warpRemoveAction = SKAction.removeFromParent()
        warp.run(SKAction.sequence([warpAnimAction,warpRemoveAction]))
    }
}
