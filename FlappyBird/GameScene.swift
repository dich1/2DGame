//
//  GameScene.swift
//  FlappyBird
//
//  Created by 伊藤 大智 on 2017/02/26.
//  Copyright © 2017年 daichi.itoh. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    // 各ノード
    var scrollNode:SKNode!
    var wallNode:SKNode!
    var bird:SKSpriteNode!
    
    // 衝突判定カテゴリ
    let birdCategory: UInt32 = 1 << 0    // 0...00001
    let groundCategory: UInt32 = 1 << 1  // 0...00010
    let wallCategory: UInt32 = 1 << 2    // 0...00100
    let scoreCategory: UInt32 = 1 << 3   // 0...01000
    
    // スコア関連フィールド
    var score = 0
    var scoreLabelNode: SKLabelNode!
    var bestScoreLabelNode: SKLabelNode!
    let userDefaults: UserDefaults = UserDefaults.standard
    
    /**
     * シーンが表示されたときに呼ばれるメソッド
     * @param view
     */
    override func didMove(to view: SKView) {
        // 重力設定
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -4.0)
        physicsWorld.contactDelegate = self
        
        // 背景色を設定
        backgroundColor = UIColor(colorLiteralRed: 0.15, green: 0.75, blue: 0.90, alpha: 1)
        
        // スクロールするスプライトを制御するための親ノードを追加
        scrollNode = SKNode()
        addChild(scrollNode)
        
        // 壁用のノードを追加
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
        
        // スプライトの作成
        setupGround()
        setupCloud()
        setupWall()
        setupBird()
        
        // スコア設定
        setupScoreLabel()
        
    }
    
    /**
     * スコア設定メソッド
     */
    func setupScoreLabel() {
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.black
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 30)
        scoreLabelNode.zPosition = 100
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "Score:\(score)"
        self.addChild(scoreLabelNode)
        
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.black
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        bestScoreLabelNode.zPosition = 100
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        
        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode.text = "Best Score:\(bestScore)"
        self.addChild(bestScoreLabelNode)
    }
    
    /**
     * リスタートをするメソッド
     */
    func restart() {
        // 初期状態に設定
        score = 0
        scoreLabelNode.text = String("Score:\(score)")
        
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zPosition = 0.0
        
        wallNode.removeAllChildren()
        
        bird.speed = 1
        scrollNode.speed = 1
    }
    
    /**
     * タップ時に呼ばれるメソッド
     * @param touches
     * @param event
     */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if scrollNode.speed > 0 {
            // 鳥の速度をゼロにする
            bird.physicsBody?.velocity = CGVector.zero
            
            // 鳥に縦方向の力を与える
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
        } else if bird.speed == 0 {
            restart()
        }
        
    }
    
    /**
     * 衝突時に呼ばれるメソッド(SKPhysicsContactDelegateのメソッド)
     * @param contact
     */
    func didBegin(_ contact: SKPhysicsContact) {
        // ゲームオーバー時は何もしない
        if scrollNode.speed <= 0 {
            return
        }
        
        // 物体の衝突判定
        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
            // 隙間通過時はスコア用物体と衝突
            print("ScoreUp")
            score += 1
            scoreLabelNode.text = "Score:\(score)"
            
            // ベストスコア更新を確認
            var bestScore = userDefaults.integer(forKey: "BEST")
            if score > bestScore {
                bestScore = score
                bestScoreLabelNode.text = "Best Score:\(bestScore)"
                userDefaults.set(bestScore, forKey: "BEST")
                userDefaults.synchronize()
            }
        } else {
            // 壁または地面と衝突
            print("GameOver")
            scrollNode.speed = 0
            bird.physicsBody?.collisionBitMask = groundCategory
            
            let roll = SKAction.rotate(byAngle: CGFloat(M_PI) * CGFloat(bird.position.y) * 0.01, duration: 1)
            bird.run(roll, completion: {
                self.bird.speed = 0
            })
            
        }
    }
    
    /**
     * 地面のスプライトを設定するメソッド
     */
    func setupGround() {
        // 地面の画像を生成
        let groundTexture = SKTexture(imageNamed: "ground")
        // 処理モードを速いものに設定(画像は荒い)
        groundTexture.filteringMode = SKTextureFilteringMode.nearest
        
        // スクロール時に必要な画像の枚数を計算
        let needNumber = 2.0 + (frame.size.width / groundTexture.size().width)
        
        // 左に画像1枚分スクロールさせるアクションの設定
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 5.0)
        
        // 元の位置に戻すアクションの設定
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0.0)
        
        // アクションのリピート設定
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))
        
        // 地面のスプライト配置
        stride(from: 0.0, to: needNumber, by: 1.0).forEach { i in
            // テクスチャを指定してスプライトを作成
            let groundSprite = SKSpriteNode(texture: groundTexture)
            
            // スプライトの表示位置を指定
            groundSprite.position = CGPoint(x: i * groundSprite.size.width / 2, y: groundTexture.size().height / 2)
            
            // スプライトにアクションを指定
            groundSprite.run(repeatScrollGround)
            
            // スプライトに物理演算を設定
            groundSprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
            
            // 衝突のカテゴリ設定
            groundSprite.physicsBody?.categoryBitMask = groundCategory
            
            // 衝突時に動かないように設定
            groundSprite.physicsBody?.isDynamic = false
            
            // シーンにスプライトを追加
            scrollNode.addChild(groundSprite)
        }
    }
    
    /**
     * 雲のスプライトを設定するメソッド
     */
    func setupCloud() {
        // 雲の画像を生成
        let cloudTexture = SKTexture(imageNamed: "cloud")
        // 処理モードを速いものに設定(画像は荒い)
        cloudTexture.filteringMode = SKTextureFilteringMode.nearest
        
        // スクロール時に必要な画像の枚数を計算
        let needCloudNumber = 2.0 + (frame.size.width / cloudTexture.size().width)
        
        // 左に画像1枚分スクロールさせるアクションの設定
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width, y: 0, duration: 20.0)
        
        // 元の位置に戻すアクション
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0.0)
        
        // アクションのリピート設定
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud, resetCloud]))
        
        // 雲のスプライトを配置
        stride(from: 0.0, to: needCloudNumber, by: 1.0).forEach { i in
            let cloudSprite = SKSpriteNode(texture: cloudTexture)
            // 一番後ろ
            cloudSprite.zPosition = -100
            
            // スプライトの表示位置を指定
            cloudSprite.position = CGPoint(x: i * cloudSprite.size.width, y: size.height - cloudTexture.size().height / 2)
            
            // スプライトにアクションを指定
            cloudSprite.run(repeatScrollCloud)
            
            // スプライトを追加
            scrollNode.addChild(cloudSprite)
            
        }
    }
    
    /**
     * 壁のスプライトを設定するメソッド
     */
    func setupWall() {
        // 壁の画像を生成
        let wallTexture = SKTexture(imageNamed: "wall")
        // 処理モードを遅いものに設定(画像はきれい)
        wallTexture.filteringMode = SKTextureFilteringMode.linear
        
        // 移動させる範囲の距離を取得
        let movingDistance = CGFloat(self.frame.size.width + wallTexture.size().width)
        
        // 移動するアクションを設定
        let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration: 4.0)
        
        // 削除のアクションを設定
        let removeWall = SKAction.removeFromParent()
        
        // 2つのアニメーションの順番を設定
        let wallAnimation = SKAction.sequence([moveWall, removeWall])
        
        // 壁を生成するアクションを作成
        let createWallAnimation = SKAction.run({
            // 壁のノードの位置を調整するためにノードを作成
            let wall = SKNode()
            wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0.0)
            // 雲より手前、地面より奥に設定
            wall.zPosition = -50.0
            
            // 画面の縦軸の中央値を取得
            let center_y = self.frame.size.height / 2
            // 縦に上下させる範囲の上限値を取得
            let random_y_range = self.frame.size.height / 4
            // 壁の隙間を通るというものなので上の壁、下の壁を設定する
            // ランダムに動く下の壁の縦軸の下限値を取得
            let under_wall_lowest_y = UInt32(center_y - wallTexture.size().height / 2 - random_y_range / 2)
            // ランダムな整数を取得
            let random_y = arc4random_uniform(UInt32(random_y_range))
            // 縦軸の下限にランダム値を足し、毎回登場する壁のY座標を決定
            let under_wall_y = CGFloat(under_wall_lowest_y + random_y)
            
            // 通り抜ける隙間の長さ
            let slit_length = self.frame.size.height / 5
            
            // 下の壁のスプライトを追加
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0.0, y: under_wall_y)
            wall.addChild(under)
            
            // 下の壁に物理演算を設定
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            // 下の壁にカテゴリを設定
            under.physicsBody?.categoryBitMask = self.wallCategory
            
            // 衝突時に動きを停止
            under.physicsBody?.isDynamic = false
            
            // 上側の壁のスプライトを追加
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0.0, y: under_wall_y + wallTexture.size().height + slit_length)
            
            // 上の壁に物理演算を設定
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            // 上の壁にカテゴリを設定
            upper.physicsBody?.categoryBitMask = self.wallCategory
            
            // 衝突時に動きを停止
            upper.physicsBody?.isDynamic = false
            
            wall.addChild(upper)
            
            // スコアアップ用ノードを鳥に設定
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + self.bird.size.width / 2, y: self.frame.height / 2.0)
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.isDynamic = false
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory
            
            // スプライトにアクションを設定
            wall.run(wallAnimation)
            
            // ノードにスプライトを追加
            self.wallNode.addChild(wall)
        })
        
        // 出現する壁の作成までの待ち時間をアクションに設定
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        // 壁の作成 -> 待ち時間リピートするアクションを設定
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation, waitAnimation]))
        
        // シーンにアクションを設定
        wallNode.run(repeatForeverAnimation)
    }
    
    /**
     * 鳥のスプライトを設定するメソッド
     */
    func setupBird() {
        // 鳥の画像を2種類生成
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = SKTextureFilteringMode.linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = SKTextureFilteringMode.linear
        
        // 2種類の画像を交互に変更するアニメーションを設定
        let texturesAnimation = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(texturesAnimation)
        
        // スプライトを生成
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        
        // 物理演算を受けるように設定(半径)
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2.0)
        
        // 衝突時に回転させない
        bird.physicsBody?.allowsRotation = false
        // 衝突のカテゴリ設定
        // 鳥自身のカテゴリ設定
        bird.physicsBody?.categoryBitMask = birdCategory
        // 衝突時に操作する対象を設定
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        // 衝突の判定をする対象のカテゴリを設定
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory
        
        // アニメーションを設定
        bird.run(flap)
        
        // スプライトを追加
        addChild(bird)
    }
    
}
