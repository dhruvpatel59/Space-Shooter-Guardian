//
//  AuthViewController.swift
//  Space Shooter  Game
//
//  Created by Antigravity on 10/04/26.
//

import UIKit

/**
 * AuthViewController.swift
 * Handles pilot authentication and enlistment.
 * Implements a modern glassmorphism UI with interactive parallax effects.
 */
class AuthViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        view.layer.cornerRadius = 20
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let glassEffect: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .dark)
        let view = UIVisualEffectView(effect: blur)
        view.layer.cornerRadius = 20
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "SPACE SHOOTER"
        label.font = UIFont(name: "AvenirNext-Heavy", size: 42)
        label.textColor = .cyan
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "GALAXY GUARDIAN"
        label.font = UIFont(name: "AvenirNext-Bold", size: 14)
        label.textColor = .white
        label.alpha = 0.6
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let leaderboardLabel: UILabel = {
        let label = UILabel()
        label.text = "ARCHIVING TOP ACES..."
        label.font = UIFont(name: "AvenirNext-MediumItalic", size: 13)
        label.textColor = .systemYellow
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let modeSegmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["DEPLOY", "ENLIST"])
        sc.selectedSegmentIndex = 0
        sc.selectedSegmentTintColor = .cyan
        sc.setTitleTextAttributes([.foregroundColor: UIColor.black, .font: UIFont.boldSystemFont(ofSize: 13)], for: .selected)
        sc.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 13)], for: .normal)
        sc.translatesAutoresizingMaskIntoConstraints = false
        return sc
    }()
    
    private let emailField: UITextField = {
        let tf = UITextField()
        tf.attributedPlaceholder = NSAttributedString(string: "Pilot Callsign (Email)", attributes: [.foregroundColor: UIColor.lightGray])
        tf.borderStyle = .none
        tf.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        tf.layer.cornerRadius = 12
        tf.textColor = .white
        tf.keyboardType = .emailAddress
        tf.autocapitalizationType = .none
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 50))
        tf.leftViewMode = .always
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let passwordField: UITextField = {
        let tf = UITextField()
        tf.attributedPlaceholder = NSAttributedString(string: "Security Code", attributes: [.foregroundColor: UIColor.lightGray])
        tf.borderStyle = .none
        tf.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        tf.layer.cornerRadius = 12
        tf.textColor = .white
        tf.isSecureTextEntry = true
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 50))
        tf.leftViewMode = .always
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let actionButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("IGNITION", for: .normal)
        button.titleLabel?.font = UIFont(name: "AvenirNext-Heavy", size: 18)
        button.backgroundColor = .cyan
        button.setTitleColor(.black, for: .normal)
        button.layer.cornerRadius = 15
        button.layer.shadowColor = UIColor.cyan.cgColor
        button.layer.shadowRadius = 10
        button.layer.shadowOpacity = 0.5
        button.layer.shadowOffset = .zero
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont(name: "AvenirNext-Medium", size: 14)
        label.textColor = .systemRed
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateLeaderboard()
    }
    
    private func updateLeaderboard() {
        let users = AuthManager.shared.getAllUsers()
        if let topUser = users.max(by: { $0.highScore < $1.highScore }), topUser.highScore > 0 {
            let name = topUser.email.prefix(upTo: topUser.email.firstIndex(of: "@") ?? topUser.email.endIndex)
            leaderboardLabel.text = "TOP ACE: \(name) - \(topUser.highScore)"
        } else {
            leaderboardLabel.text = "NO ACES DEPLOYED YET"
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.colors = [
            UIColor(red: 0, green: 0.05, blue: 0.1, alpha: 1).cgColor,
            UIColor.black.cgColor,
            UIColor(red: 0, green: 0.1, blue: 0.15, alpha: 1).cgColor
        ]
        view.layer.insertSublayer(gradient, at: 0)
        
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(leaderboardLabel)
        view.addSubview(containerView)
        
        containerView.addSubview(glassEffect)
        containerView.addSubview(modeSegmentedControl)
        containerView.addSubview(emailField)
        containerView.addSubview(passwordField)
        containerView.addSubview(actionButton)
        containerView.addSubview(statusLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            leaderboardLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            leaderboardLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            containerView.topAnchor.constraint(equalTo: leaderboardLabel.bottomAnchor, constant: 40),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            containerView.bottomAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 30),
            
            glassEffect.topAnchor.constraint(equalTo: containerView.topAnchor),
            glassEffect.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            glassEffect.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            glassEffect.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            modeSegmentedControl.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 30),
            modeSegmentedControl.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            modeSegmentedControl.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            modeSegmentedControl.heightAnchor.constraint(equalToConstant: 35),
            
            emailField.topAnchor.constraint(equalTo: modeSegmentedControl.bottomAnchor, constant: 30),
            emailField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            emailField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            emailField.heightAnchor.constraint(equalToConstant: 50),
            
            passwordField.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: 16),
            passwordField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            passwordField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            passwordField.heightAnchor.constraint(equalToConstant: 50),
            
            actionButton.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 30),
            actionButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            actionButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            actionButton.heightAnchor.constraint(equalToConstant: 55),
            
            statusLabel.topAnchor.constraint(equalTo: actionButton.bottomAnchor, constant: 16),
            statusLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20)
        ])
        
        actionButton.addTarget(self, action: #selector(handleAction), for: .touchUpInside)
        actionButton.addTarget(self, action: #selector(buttonTouched), for: .touchDown)
        actionButton.addTarget(self, action: #selector(buttonReleased), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        modeSegmentedControl.addTarget(self, action: #selector(handleModeChange), for: .valueChanged)
        
        applyParallax()
    }
    
    private func applyParallax() {
        let horizontal = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        horizontal.minimumRelativeValue = -15
        horizontal.maximumRelativeValue = 15
        
        let vertical = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
        vertical.minimumRelativeValue = -15
        vertical.maximumRelativeValue = 15
        
        let group = UIMotionEffectGroup()
        group.motionEffects = [horizontal, vertical]
        containerView.addMotionEffect(group)
        titleLabel.addMotionEffect(group)
    }
    
    @objc private func buttonTouched() {
        UIView.animate(withDuration: 0.1) {
            self.actionButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }
    
    @objc private func buttonReleased() {
        UIView.animate(withDuration: 0.1) {
            self.actionButton.transform = .identity
        }
    }
    
    @objc private func handleModeChange() {
        let isLogin = modeSegmentedControl.selectedSegmentIndex == 0
        actionButton.setTitle(isLogin ? "IGNITION" : "ENLIST", for: .normal)
        statusLabel.text = ""
    }
    
    @objc private func handleAction() {
        guard let email = emailField.text, !email.isEmpty,
              let password = passwordField.text, !password.isEmpty else {
            statusLabel.text = "Credentials required for takeoff."
            return
        }
        
        if modeSegmentedControl.selectedSegmentIndex == 0 {
            // Login
            if AuthManager.shared.login(email: email, password: password) {
                navigateToGame()
            } else {
                statusLabel.text = "Authentication failed. Check your data."
            }
        } else {
            // Sign Up
            let result = AuthManager.shared.signUp(email: email, password: password)
            if result.success {
                navigateToGame()
            } else {
                statusLabel.text = result.message
            }
        }
    }
    
    private func navigateToGame() {
        let gameVC = GameViewController()
        gameVC.modalPresentationStyle = .fullScreen
        gameVC.modalTransitionStyle = .flipHorizontal
        self.present(gameVC, animated: true, completion: nil)
    }
}
