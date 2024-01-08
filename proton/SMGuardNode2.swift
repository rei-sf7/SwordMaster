//
//  SMGuardNode2.swift
//  proton
//
//  Created by KakimotoMasaaki on 2015/08/08.
//  Copyright (c) 2015年 Masaaki Kakimoto. All rights reserved.
//

import Foundation
import SpriteKit

//自機用のバリアクラス
class SMGuardNode2: SMGuardNode {
    //初期化
    override init(texture: SKTexture, location: CGPoint, parentnode:SKNode){
        super.init(texture: texture, location: location, parentnode: parentnode)
        self.hitpoint = 20
    }
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func makeGuard() {
        super.makeGuard()
        self.physicsBody?.restitution = 1.5
        self.physicsBody?.categoryBitMask = ColliderType.Guard2
        self.physicsBody?.collisionBitMask = ColliderType.Enegy
        self.physicsBody?.contactTestBitMask = ColliderType.Enegy
    }
    func makeGuardGold() {
        super.makeGuard()
        self.hitpoint = 100
        self.physicsBody?.restitution = 3.0
        self.physicsBody?.categoryBitMask = ColliderType.Guard2
        self.physicsBody?.collisionBitMask = ColliderType.Enegy
        self.physicsBody?.contactTestBitMask = ColliderType.Enegy
        self.color = UIColor.yellow
        self.colorBlendFactor = 0.7
        self.run(SKAction.scale(by: 1.3, duration: 1.0))
    }
    //弾が当たった時の処理
    func hitEnegy(enegy: SMEnegyNode) {
        let damage = 1
        hitpoint -= (damage)
        //enegy.physicsBody?.categoryBitMask = ColliderType.None
        let fadeIn = SKAction.fadeIn(withDuration: 0)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        
        if hitpoint <= 3 {
            //バリアが壊れそうな時は赤くする
            self.color = UIColor.red
            self.colorBlendFactor = 0.7
        }
        
        if hitpoint <= 0 {
            //バリア破壊
            bgNode.run(explodeSound2)
            SMNodeUtil.makeParticleNode(position: self.position, filename:"deadParticle.sks", node:bgNode)
            SMNodeUtil.fadeRemoveNode(removenode: self)
        } else {
            hit.run(SKAction.sequence([fadeIn, guardAnimAction, fadeOut]))
            bgNode.run(kakinSound)
        }
    }
}
