//
//  SMGuardNode.swift
//  proton
//
//  Created by KakimotoMasaaki on 2015/08/05.
//  Copyright (c) 2015年 Masaaki Kakimoto. All rights reserved.
//

import Foundation
import SpriteKit

//敵用のバリアクラス
class SMGuardNode: SKSpriteNode {
    //耐久力
    var hitpoint: Int = 20
    //親ノード
    weak var parentnode: SKNode?
    
    //ヒットエフェクト
    var hit: SKSpriteNode!
    
    //初期化
    init(texture: SKTexture, location: CGPoint, parentnode:SKNode){
        self.parentnode = parentnode
        let color = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
        super.init(texture: texture, color:color, size:texture.size())
        self.position = CGPoint(x:location.x, y:location.y)
        self.zPosition = 2
        self.blendMode = SKBlendMode.add
        self.alpha = 0.8
        self.hitpoint = self.hitpoint + (self.hitpoint * stageManager.clearNum) //クリアする度に難しくなる
        
        //アニメーションを作成
        hit = SKSpriteNode(texture: hitAim[0], size: hitAim[0].size())
        hit.blendMode = SKBlendMode.add
        hit.alpha = 0.5
        hit.zPosition = 3
        self.addChild(hit!)
    }
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func makeGuard() {
        //物理シミュレーション設定
        //self.physicsBody = SKPhysicsBody(texture: self.texture!, size: self.texture!.size())
        self.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 100, height: 30))
        self.physicsBody?.isDynamic = false
        self.physicsBody?.allowsRotation = false
        self.physicsBody?.density = 1000.0
        
        self.physicsBody?.categoryBitMask = ColliderType.Guard
        self.physicsBody?.collisionBitMask = ColliderType.Sword
        self.physicsBody?.contactTestBitMask = ColliderType.Sword
        
        parentnode!.addChild(self)
    }
    //剣が当たった時の処理
    func hitSword(sword: SMSwordNode) {
        let damage = sword.attack
        hitpoint -= (damage)
        sword.physicsBody?.categoryBitMask = ColliderType.None
        let parent = self.parentnode
        if hitpoint <= 3 {
            //バリアが壊れそうな時は赤くする
            self.color = UIColor.red
            self.colorBlendFactor = 0.7
        }
        if hitpoint <= 0 {
            //バリア破壊
            bgNode.run(explodeSound2)
            SMNodeUtil.makeParticleNode(position: parent!.position, filename:"deadParticle.sks", node:bgNode)
            SMNodeUtil.fadeRemoveNode(removenode: self)
            //self.removeFromParent()
        } else {
            hit.removeAllActions()
            let fadeIn = SKAction.fadeIn(withDuration: 0)
            let fadeOut = SKAction.fadeOut(withDuration: 0.5)
            hit.run(SKAction.sequence([fadeIn, guardAnimAction, fadeOut]))
            bgNode.run(kakinSound)
            SMNodeUtil.makeParticleNode(position: parent!.position, filename:"hitParticle.sks", node:bgNode)
        }
    }
}
