//
//  GameViewController.swift
//  Nurikabe
//
//  Created by Lena Trnovec on 8/12/25.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as! SKView? {
            // Load the MenuScene instead of GameScene
            let scene = MenuScene()
            scene.size = view.bounds.size
            scene.scaleMode = .aspectFill
            
            // Present the menu scene
            view.presentScene(scene)
            
            view.ignoresSiblingOrder = true
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
