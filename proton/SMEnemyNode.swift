//
//  SMEnemyNode.swift
//  proton
//
//  Created by KakimotoMasaaki on 2015/07/12.
//  Copyright (c) 2015年 Masaaki Kakimoto. All rights reserved.
//

import Foundation
import SpriteKit

class SMEnemyNode: SKSpriteNode {
    //敵タイプ
    var type: EnemyType!
    var inithitpoint = 0
    var smokecount = 0
    
    //耐久力
    var hitpoint: Int = 1
    //防御力
    var diffence: Int = 0
    //親ノード
    weak var parentnode: SKNode?
    //スコア
    var score: Int = 1
    
    //死んだ時の通知用
    weak var delegate: SMEnemyGroup?
    
    //ヒットエフェクト
    var hit: SKSpriteNode!
    
    //ボスかどうか
    var isBoss: Bool = false
    
    //アイテムの数
    var itemnum = 1
    
    //たいあたり中かどうか
    var isAttack = false
    
    //初期化
    init(texture: SKTexture, type: EnemyType, location: CGPoint, parentnode:SKNode){
        self.type = type
        self.parentnode = parentnode
        let color = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
        super.init(texture: texture, color:color, size:texture.size())
        self.position = CGPoint(x:location.x, y:location.y)
        self.zPosition = 2
    }
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //敵の作成
    func makeEnemy() {
        //物理シミュレーションを設定
        /*
        if #available(iOS 8.0, *) {
            self.physicsBody = SKPhysicsBody(texture: self.texture!, size: self.texture!.size())
            self.shadowCastBitMask = 1
        } else {
            // Fallback on earlier versions
            self.physicsBody = SKPhysicsBody(rectangleOfSize: self.texture!.size())
        }*/
        self.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: self.texture!.size().width * 0.8, height:self.texture!.size().height/2 ))
        self.physicsBody?.isDynamic = true
        self.physicsBody?.allowsRotation = true
        self.physicsBody?.restitution = 0.5
        self.physicsBody?.categoryBitMask = ColliderType.Enemy
        self.physicsBody?.collisionBitMask = ColliderType.Player | ColliderType.Sword
        self.physicsBody?.contactTestBitMask = ColliderType.Player | ColliderType.Sword
        
        if let parentnode = self.parentnode {
            parentnode.addChild(self)
        }
        //フェードインする
        self.alpha = 0.0
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        self.run(fadeIn)
        //アニメーションを作成
        hit = SKSpriteNode(texture: hitAim[0], size: hitAim[0].size())
        hit.blendMode = SKBlendMode.add
        hit.alpha = 0.5
        hit.zPosition = 3
        self.addChild(hit!)
    }
    func makeEnegy(num: Int) {
        let tmpnum = num + (num * stageManager.clearNum) // クリアする度に難しくなる
        weak var tmpself = self
        let custumAction = SKAction.customAction(withDuration: 0.0, actionBlock: { (node: SKNode, elapsedTime: CGFloat) -> Void in
            let rand:CGFloat = CGFloat(arc4random_uniform(100))
            let custumAction2 = SKAction.customAction(withDuration: 0.0, actionBlock: { (node: SKNode, elapsedTime: CGFloat) -> Void in
                if tmpself!.isAttack {
                    //たいあたり中は弾を出さないようにする
                    return
                }
                //弾発射
                let point = CGPoint(x: self.position.x , y: self.position.y)
                for _ in 0..<tmpnum {
                    let enegy = enegyFactory.create(position: point)
                    enegy.makeEnegy()
                    enegy.shotEnegyRandom()
                }
            })
            let waitAction2 = SKAction.wait(forDuration: 0.03 * Double(rand))
            tmpself?.run(SKAction.sequence([waitAction2,custumAction2]))
        })
        let waitAction = SKAction.wait(forDuration: 1.5)
        self.run(SKAction.repeatForever(SKAction.sequence([waitAction,custumAction])))
    }
    func makeEnegy2(interval: Double = 5.0) {
        //println("makeEnegy2()")
        let custumAction = SKAction.customAction(withDuration: 0.0, actionBlock: { (node: SKNode, elapsedTime: CGFloat) -> Void in
            //println("makeEnegy2() customAction")
            let rand:CGFloat = CGFloat(arc4random_uniform(100))
            let custumAction2 = SKAction.customAction(withDuration: 0.0, actionBlock: { (node: SKNode, elapsedTime: CGFloat) -> Void in
                let point = CGPoint(x: self.position.x , y: self.position.y)
                let enegy = enegyFactory.create(position: point)
                enegy.makeEnegy(rad: 10.0, den: 100.0)
                //enegy.shotEnegyRandom()
                enegy.shotEnegyPlayer()
                let scale = SKAction.scale(by: 3.0, duration: 1.0)
                enegy.run(scale)
                SMNodeUtil.makeParticleNode(position: CGPoint(x:0,y:0), filename: "enegyParticle.sks", hide: false, node: enegy)
                //光の演出を付ける
                if #available(iOS 8.0, *) {
                    let light:SKLightNode = SKLightNode()
                    light.categoryBitMask = 1
                    light.falloff = 1
                    light.ambientColor = UIColor.white
                    light.lightColor = UIColor(red: 1.0, green: 0.9, blue: 0.9, alpha: 0.9)
                    light.shadowColor = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 0.3)
                    enegy.addChild(light)
                } else {
                    // Fallback on earlier versions
                }
            })
            let waitAction2 = SKAction.wait(forDuration: 0.03 * Double(rand))
            bgNode.run(SKAction.sequence([waitAction2,custumAction2]))
        })
        let waitAction = SKAction.wait(forDuration: interval)
        self.run(SKAction.repeatForever(SKAction.sequence([waitAction,custumAction])))
    }
    //剣が当たった時の処理
    func hitSword(sword: SMSwordNode) {
        if inithitpoint == 0 {
            inithitpoint = hitpoint //初期HP
        }
        let damage = sword.attack - diffence - (stageManager.clearNum) //周回するごとに難しくなる
        sword.attack = Int(Double(damage) * 0.8)
        sword.hitpoint -= 1
        
        //剣のパーティクル削除
        for child in sword.children {
            child.removeFromParent()
        }
        
        if damage <= 0 {
            hit.removeAllActions()
            //ダメージを与えられない
            let fadeIn = SKAction.fadeIn(withDuration: 0)
            let fadeOut = SKAction.fadeOut(withDuration: 0.5)
            let guardAnimAction = SKAction.animate(with: guardAim, timePerFrame: 0.1, resize:false, restore:true)
            hit.run(SKAction.sequence([fadeIn,guardAnimAction,fadeOut]))
            bgNode.run(kakinSound)
            return
        }
        hitpoint -= (damage)
        
        //コンボの処理
        let waitAction = SKAction.wait(forDuration: 1.0)
        let custumAction = SKAction.customAction(withDuration: 0.0, actionBlock: { (node: SKNode, elapsedTime: CGFloat) -> Void in
            combo = 0
            comboLabel.alpha = 0.0
        })
        comboLabel.removeAllActions()
        comboLabel.run(SKAction.sequence([waitAction, custumAction]))
        combo += 1
        if combo > 1 {
            comboLabel.text = "\(combo) Combo!"
            bgNode.run(comboSound)
            bgNode.run(comboSound)
            bgNode.run(comboSound)
            //comboLabel.alpha = 1.0
            if comboLabel.alpha == 0.0 {
                
                let fadeInAction = SKAction.fadeIn(withDuration: 0.5)
                let fadeInAction2 = SKAction.fadeAlpha(to: 0.3, duration: 0.5)
                let fadeOutAction = SKAction.fadeOut(withDuration: 0.5)
                
                comboLabel.run(fadeInAction)
                //let x = comboLabel.position.x
                let scale1 = SKAction.scale(to: 1.0, duration: 0.0)
                let scale2 = SKAction.scale(to: 3.0, duration: 2.0)
                let move1 = SKAction.moveTo(x: self.scene!.frame.width + 10.0, duration: 0.0)
                let move2 = SKAction.moveTo(x: self.scene!.frame.width - 200.0, duration: 0.5)
                comboLabel.run(SKAction.sequence([scale1, move1,move2, scale2]))
                bgNode.run(koredeSound)
                
                enemysNode.speed = 0.1
                enemysNode.scene!.physicsWorld.gravity = CGVector(dx:0.0, dy:0.40)
                let custumAction = SKAction.customAction(withDuration: 0.0, actionBlock: { (node: SKNode, elapsedTime: CGFloat) -> Void in
                    enemysNode.speed = 1.0
                    enemysNode.scene!.physicsWorld.gravity = CGVector(dx:0.0, dy:-0.10)
                })
                let waitAction = SKAction.wait(forDuration: 0.7)
                bgNode.run(SKAction.sequence([waitAction,custumAction]))
                
                let killAnimAction = SKAction.animate(with: killAim, timePerFrame: 0.1, resize:false, restore:true)
                killAimNode.run(killAnimAction)
                killAimNode.run(SKAction.sequence([fadeInAction2,fadeOutAction]) )
                killAimNode.run(SKAction.sequence([scale1,scale2]))
                //光の演出を付ける
                if #available(iOS 8.0, *) {
                    let light:SKLightNode = SKLightNode()
                    light.categoryBitMask = 1
                    light.falloff = 1
                    light.ambientColor = UIColor.white
                    light.lightColor = UIColor(red: 1.0, green: 0.9, blue: 0.9, alpha: 0.9)
                    light.shadowColor = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 0.3)
                    sword.addChild(light)
                } else {
                    // Fallback on earlier versions
                }
            } else {
                comboLabel.alpha = 1.0
                let move2 = SKAction.moveTo(x: self.scene!.frame.width - 100.0, duration: 0.0)
                comboLabel.run(SKAction.sequence([move2]))
            }
        }
        
        if sword.hitpoint <= 0 || sword.attack <= 0 {
            sword.physicsBody?.categoryBitMask = ColliderType.None
        }
        if hitpoint <= 0 {
            //敵が死んだ時の処理
            dead()
        } else {
            bgNode.run(explodeSound2)
            SMNodeUtil.makeParticleNode(position: self.position, filename:"hitParticle.sks", node:bgNode)
            let hitAnimAction = SKAction.animate(with: hitAim, timePerFrame: 0.03, resize:false, restore:true)
            hit.removeAllActions()
            hit.run(hitAnimAction)
            hit.alpha = 0.8
            let fadeout = SKAction.fadeOut(withDuration: 1.0)
            hit.run(fadeout)
            
            var smokecountmax = 3
            if hitpoint <= (inithitpoint/2) {
                self.color = UIColor.red
                self.colorBlendFactor = 0.2
                if hitpoint <= (inithitpoint/4) {
                    self.colorBlendFactor = 0.5
                    smokecountmax = 8
                }
                smokecount += 1
                if smokecount <= smokecountmax {
                    let rand:CGFloat = CGFloat(arc4random_uniform(10))
                    let randY:CGFloat = CGFloat(arc4random_uniform(10))
                    SMNodeUtil.makeParticleNode(position: CGPoint(x: CGFloat(rand), y: CGFloat(randY)), filename: "smoke.sks", hide: false, node: self)
                }
            }
        }
    }
    //敵が死んだ時の処理
    func dead() {
        SMNodeUtil.makeParticleNode(position: self.position, filename:"deadParticle.sks", node:bgNode)
        SMNodeUtil.makeParticleNode(position: self.position, filename:"hitParticle.sks", node:bgNode)
        SMNodeUtil.makeParticleNode(position: self.position, filename:"shopButton.sks", node:bgNode)
        self.physicsBody?.categoryBitMask = ColliderType.None
        self.removeAllActions()
        
        var itempos = self.position
        for i in 1...itemnum {
            let rand:CGFloat = CGFloat(arc4random_uniform(100))
            let randY:CGFloat = CGFloat(arc4random_uniform(100))
            var randp: CGFloat = 1.0
            var randyp: CGFloat = 1.0
            var x = self.position.x
            var y = self.position.y
            if i > 1 {
                if (CGFloat)((Int)(rand * 100) % 2) == 0 {
                    randp = -1
                }
                if (CGFloat)((Int)(randY * 100) % 2) == 0 {
                    randyp = -1
                }
                x = x + (rand * randp)
                y = y + (randY * randyp)
                itempos = CGPoint(x:x, y:y)
            }
            let item = itemFactory.createRandom(location: itempos)
            item?.makeItem()
        }
        
        var combop = 1.0
        if combo > 1 {
            combop = 1.0 * Double(combo)
        }
        totalScore = totalScore + Int(Double(self.score) * combop)
        scoreLabel.text = "\(totalScore)"
        if let delegate = self.delegate {
            delegate.enemyDeadDelegate(enemy: self)
        }
        SMNodeUtil.fadeRemoveNode(removenode: self)
        bgNode.run(explodeSound)
    }
    //デイニシャライザ
    deinit {
        //println("enemy deinit")
    }
    
    //x座標をプレイヤーに追尾する
    func moveXToPlayer(duration:Double = 2.0) {
        weak var tmpself = self
        let custumAction = SKAction.customAction(withDuration: 0.0, actionBlock: { (node: SKNode, elapsedTime: CGFloat) -> Void in
            let moveX = SKAction.moveTo(x: player.position.x, duration: duration)
            tmpself!.run(SKAction.sequence([moveX]))
        })
        let waitAction = SKAction.wait(forDuration: 1.0 + duration)
        self.run(SKAction.repeatForever(SKAction.sequence([waitAction,custumAction])))
    }
    
    func attackPlayer(duration: Double) {
        weak var tmpself = self
        let randX = arc4random_uniform(140)
        var fx:CGFloat = CGFloat(randX)
        if (randX % 2) == 0 {
            fx = fx * CGFloat(-1)
        }
        let custumAction = SKAction.customAction(withDuration: 0.0, actionBlock: { (node: SKNode, elapsedTime: CGFloat) -> Void in
            tmpself!.isAttack = true
            let move = SKAction.move(to: player.position, duration: 3.0)
            let removeX = SKAction.moveBy(x: fx, y: frameHeight - 120, duration: 1.0)
            //let removeX = SKAction.moveTo(CGPoint(x:100 + fx, y:frameHeight - 120), duration: 1.0)
            let custumAction2 = SKAction.customAction(withDuration: 0.0, actionBlock: { (node: SKNode, elapsedTime: CGFloat) -> Void in
                tmpself!.isAttack = false
            })
            tmpself!.run(SKAction.sequence([move,removeX,custumAction2]))
        })
        let waitAction = SKAction.wait(forDuration: duration)
        self.run(SKAction.repeatForever(SKAction.sequence([waitAction,custumAction])))
    }
}
