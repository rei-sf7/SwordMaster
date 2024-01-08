//
//  SMEnemyBoss2.swift
//  proton
//
//  Created by KakimotoMasaaki on 2015/08/03.
//  Copyright (c) 2015年 Masaaki Kakimoto. All rights reserved.
//

import Foundation
import SpriteKit

class SMEnemyBoss2: SMEnemyNode {
    var `guard`: SMGuardNode!
    init(texture: SKTexture) {
        var x:CGFloat = 0
        var y:CGFloat = 0
        x = frameWidth/2
        y = CGFloat(frameHeight)
        let location = CGPoint(x:x, y:y)
        super.init(texture: texture, type: EnemyType.BOSS2, location: location, parentnode: enemysNode)
        //self.isBoss = true
        self.hitpoint = 160
        if debugflg {
            self.hitpoint = 1
        }
        self.diffence = 1
        self.score = 20000
        self.itemnum = 20
    }
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func makeEnemy() {
        super.makeEnemy()
        
        if #available(iOS 8.0, *) {
            self.shadowCastBitMask = 1
        } else {
            // Fallback on earlier versions
        }
        //self.physicsBody?.dynamic = false
        self.physicsBody?.affectedByGravity = false
        self.physicsBody?.restitution = 0.1
        self.physicsBody?.density = 1000.0
        makeEnegy(num: 30)
        makeEnegy2(interval: 3.0)
        let move = SKAction.moveTo(y: frameHeight - 100, duration: 3.0)
        self.run(move)
        self.moveXToPlayer()
        //バリアを作成
        let guardpos = CGPoint(x:-10, y:-80)
        `guard` = SMGuardNode(texture: guardTexture, location: guardpos, parentnode: self)
        `guard`.makeGuard()
        `guard`.hitpoint = 80
        
        attackPlayer(duration: 20.0)
    }
}
