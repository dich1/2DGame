//
//  ViewController.swift
//  FlappyBird
//
//  Created by 伊藤 大智 on 2017/02/19.
//  Copyright © 2017年 daichi.itoh. All rights reserved.
//

import UIKit
import SpriteKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // SKViewに変換
        let skView = self.view as! SKView
        // FPSを表示
        skView.showsFPS = true
        // ノードの数を表示
        skView.showsFPS = true
        // シーンをビューのサイズで作成
        let scene = GameScene(size:skView.frame.size)
        // ビューにシーンを表示
        skView.presentScene(scene)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }

}

