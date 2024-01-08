//
//  SMSwordNode.swift
//  proton
//
//  Created by KakimotoMasaaki on 2015/07/10.
//  Copyright (c) 2015年 Masaaki Kakimoto. All rights reserved.
//

import Foundation
import SpriteKit

class SMSwordNode: SKSpriteNode {
    //剣の種類
    var type: SwordType
    var shotSound: SKAction
    var startPoint: CGPoint
    weak var parentnode: SKNode!
    var circle: SKSpriteNode
    var swipex: Int = 0
    var isShot: Bool = false
    var count = 1
    
    //攻撃力
    var attack: Int = 1
    //耐久力
    var hitpoint: Int = 1
    //チャージスピード
    var charge: Int = 0
    
    init(texture: SKTexture, type: SwordType, shotSound:SKAction, location: CGPoint,parentnode:SKNode, startPoint: CGPoint){
        self.type = type
        self.shotSound = shotSound
        self.startPoint = startPoint
        self.parentnode = parentnode
        //self.circle = SKShapeNode(circleOfRadius: 15)
        self.circle = SKSpriteNode(imageNamed: "magic_circle")
        let color = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
        super.init(texture: texture, color:color, size:texture.size())
        self.position = CGPoint(x:location.x, y:location.y - 40)
    }
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    //剣の作成
    func makeSword(attack: Int, charge: Int){
        //let waitSoundAction = SKAction.waitForDuration(0.5)
        //let magic = SKAction.sequence([waitSoundAction, magicSound])
        //self.runAction(magic)
        //self.runAction(magic)
        //self.runAction(magic)
        self.attack = attack
        self.charge = charge
        
        //物理シミュレーション設定
        /*
        if #available(iOS 8.0, *) {
            self.physicsBody = SKPhysicsBody(texture: self.texture!, size: self.texture!.size())
        } else {
            // Fallback on earlier versions
        }*/
        self.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 15, height: 65))
        self.physicsBody?.isDynamic = false
        self.physicsBody?.allowsRotation = true
        self.physicsBody?.affectedByGravity = false
        self.physicsBody?.restitution = 2.0
        
        self.physicsBody?.categoryBitMask = ColliderType.Sword
        self.physicsBody?.collisionBitMask = ColliderType.Enemy | ColliderType.Sword | ColliderType.Enegy | ColliderType.Guard
        self.physicsBody?.contactTestBitMask = ColliderType.Enemy | ColliderType.Sword  | ColliderType.Enegy | ColliderType.Guard
        
        self.alpha = 0.0
        self.anchorPoint = CGPoint(x:0.5,y:0)
        
        parentnode.addChild(self)
        
        // 円を描画.
        makeCircle(position: self.position)
        
        self.color = UIColor.red
        self.colorBlendFactor = 0.05 * CGFloat(self.attack)
        
        //透明度を徐々に上げて登場
        let fadeInAction = SKAction.fadeIn(withDuration: 0.5)
        self.run(fadeInAction)
        
        //少し前に移動
        let frontMoveAction = SKAction.moveTo(y: self.startPoint.y + 10, duration: 0.5)
        self.run(SKAction.sequence([frontMoveAction]))
    }
    
    //魔法陣を作成する
    func makeCircle(position:CGPoint) {
        // ShapeNodeの座標を指定.
        circle.position = position
        circle.blendMode = SKBlendMode.add
        circle.alpha = 0.0
        
        // ShapeNodeの塗りつぶしの色を指定.
        //Circle.fillColor = UIColor.redColor()
        
        let scaleZeroAction = SKAction.scale(to: 0, duration: 0)
        let scaleAction = SKAction.scaleX(to: 0.4, y: 0.4, duration: 0.5)
        circle.run(SKAction.sequence([scaleZeroAction,scaleAction]))
        
        // sceneにShapeNodeを追加.
        parentnode.addChild(circle)
        
        let fadeIn = SKAction.fadeAlpha(to: 0.8, duration: 1.0)
        circle.run(fadeIn)
        
        
        //回転のアニメーション
        let rotateAction = SKAction.rotate(byAngle: CGFloat(360 * Double.pi / 180), duration: 10)
        circle.run(rotateAction)
    }
    
    //剣をスワイプする
    func swipeSword(swipepoint: CGPoint) {
        //println("swipepoint:\(swipepoint)")
        let x:Int = Int(swipepoint.x) - Int(startPoint.x)
        swipex = x * -1
        let angle: CGFloat = CGFloat(x) / CGFloat(180.0) * CGFloat(Double.pi)
        //回転のアニメーション
        //var rotateAction = SKAction.rotateByAngle(1, duration: 0)
        let rotateAction = SKAction.rotate(toAngle: angle, duration: 0)
        self.run(SKAction.sequence([rotateAction]))
    }
    
    //剣の発射
    func shotSword() {
        self.removeAllActions()
        self.alpha = 1.0
        self.anchorPoint = CGPoint(x:0.5,y:0.5)
        self.physicsBody?.isDynamic = true
        self.physicsBody?.velocity = CGVector.zero
        self.physicsBody?.applyImpulse(CGVector(dx:CGFloat(swipex), dy:70.0 + (10.0 * CGFloat(self.attack))))
        self.isShot = true
        
        if self.attack >= 3 {
            self.physicsBody?.restitution = 0
            self.physicsBody?.density = 3.0
        }
        
        //2秒後に消す
        let removeAction = SKAction.removeFromParent()
        let durationtime = 2.00 - (0.1 * Double(self.charge))
        let durationAction = SKAction.wait(forDuration: durationtime)
        let custumAction = SKAction.customAction(withDuration: 0.0, actionBlock: { (node: SKNode, elapsedTime: CGFloat) -> Void in
            if player.swordNum < player.swordMaxNum {
                player.countUpSword()
            }
        })
        let sequenceAction = SKAction.sequence([durationAction,custumAction,removeAction])
        self.run(sequenceAction)
        
        let fadeAction = SKAction.fadeAlpha(to: 0, duration: durationtime)
        self.run(fadeAction)
        
        removeCircle()
        
        //パーティクル作成
        let point = CGPoint(x:0, y:30)
        SMNodeUtil.makeMagicParticle(position: startPoint, node: parentnode)
        SMNodeUtil.makeSparkParticle(position: point, node: self)
    }
    
    func removeCircle() {
        SMNodeUtil.fadeRemoveNode(removenode: circle)
    }
    
    //デイニシャライザ
    deinit {
        //println("sword deinit")
    }
}
