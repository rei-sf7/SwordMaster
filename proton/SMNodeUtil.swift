//
//  SMParticleNode.swift
//  proton
//
//  Created by KakimotoMasaaki on 2015/07/10.
//  Copyright (c) 2015年 Masaaki Kakimoto. All rights reserved.
//

import Foundation
import SpriteKit

//NodeUtilクラス
class SMNodeUtil {
    //主人公を追尾するベクトルを作成する
    class func makePlayerVector(position: CGPoint, player: SMPlayerNode?) -> CGVector {
        if player == nil {
            return CGVector(dx: 0.0, dy: 0.0)
        }
        return CGVector(dx:player!.position.x - position.x, dy:player!.position.y - position.y)
    }
    //パーティクル作成
    class func makeParticleNode(position:CGPoint?, filename: String, hide: Bool = true, node: SKNode) {
        let particle = SKEmitterNode(fileNamed: filename)
        particle!.zPosition = 100
        node.addChild(particle!)
        
        if let tmp = position {
            particle!.position = tmp
        }
        
        //消さないんだったらリターン
        if !hide {
            return
        }
        fadeRemoveNode(removenode: particle)
    }
    //火花のパーティクル作る
    class func makeSparkParticle(position:CGPoint?, node: SKNode) {
        SMNodeUtil.makeParticleNode(position: position, filename:"sparkParticle.sks", node: node)
    }
    //魔法のパーティクルを作る
    class func makeMagicParticle(position:CGPoint?, node: SKNode) {
        SMNodeUtil.makeParticleNode(position: position, filename:"magicParticle.sks", node: node)
    }
    
    //一秒後にフェードしながらノードを消す
    class func fadeRemoveNode(removenode: SKNode!) {
        //１秒後に消す
        let removeAction = SKAction.removeFromParent()
        let durationAction = SKAction.wait(forDuration: 1.50)
        let sequenceAction = SKAction.sequence([durationAction,removeAction])
        removenode.run(sequenceAction)
        
        removenode.alpha = 1
        
        let fadeAction = SKAction.fadeAlpha(to: 0, duration: 1.0)
        removenode.run(fadeAction)
    }
    //10秒後にフェードしながらノードを消す
    class func fadeRemoveNode10(removenode: SKNode!) {
        //１秒後に消す
        let removeAction = SKAction.removeFromParent()
        let durationAction = SKAction.wait(forDuration: 5.50)
        let sequenceAction = SKAction.sequence([durationAction,removeAction])
        removenode.run(sequenceAction)
        
        removenode.alpha = 1
        
        /*
        var fadeAction = SKAction.fadeAlphaTo(0, duration: 20.0)
        removenode.runAction(fadeAction)
*/
    }
}
