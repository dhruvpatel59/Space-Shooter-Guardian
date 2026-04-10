//
//  GameViewController.swift
//  Space Shooter  Game
//
//  Created by Dhruv Patel on 09/02/25.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func loadView() {
        self.view = SKView(frame: UIScreen.main.bounds)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as? SKView {
            // Create and configure the initial menu scene
            let scene = MenuScene(size: view.bounds.size)
            scene.scaleMode = .aspectFill
            
            // Present the scene
            view.presentScene(scene)
            
            view.ignoresSiblingOrder = true
            view.showsFPS = true
            view.showsNodeCount = true
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

extension GameViewController: GameSceneDelegate {
    func didRequestLogout() {
        AuthManager.shared.logout()
        
        let authVC = AuthViewController()
        authVC.modalPresentationStyle = .fullScreen
        authVC.modalTransitionStyle = .crossDissolve
        self.present(authVC, animated: true, completion: nil)
    }
}
