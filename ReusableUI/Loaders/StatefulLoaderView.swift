//
//  StatefulLoaderView.swift
//  selfTest
//
//  Created by sowndharrajan on 20/09/26.
//

import UIKit

class StatefulLoaderView: UIView {
    
    private let spinner = UIActivityIndicatorView(style: .large)
    private let messageLabel = UILabel()
    
    init(message: String = "Fetching recipes...") {
        super.init(frame: .zero)
        configureOverlay(with: message)
    }
    
    required init?(coder: NSCoder) {
        fatalError("StatefulLoaderView uses custom code initializer protocols exclusively.")
    }
    
    private func configureOverlay(with message: String) {
        self.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        // Setup inner card containment box
        let containerBox = UIView()
        containerBox.backgroundColor = .surfaceBackground
        containerBox.layer.cornerRadius = 16
        containerBox.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(containerBox)
        
        // Setup interactive system loading spinner configuration layout engine
        spinner.color = .brandGreen
        spinner.translatesAutoresizingMaskIntoConstraints = false
        containerBox.addSubview(spinner)
        
        // Setup tracking description label indicators configurations elements
        messageLabel.text = message
        messageLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        messageLabel.textColor = .label
        messageLabel.textAlignment = .center
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        containerBox.addSubview(messageLabel)
        
        // Layout bounds alignment settings constraints
        NSLayoutConstraint.activate([
            containerBox.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            containerBox.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            containerBox.widthAnchor.constraint(equalToConstant: 180),
            containerBox.heightAnchor.constraint(equalToConstant: 140),
            
            spinner.topAnchor.constraint(equalTo: containerBox.topAnchor, constant: 28),
            spinner.centerXAnchor.constraint(equalTo: containerBox.centerXAnchor),
            
            messageLabel.topAnchor.constraint(equalTo: spinner.bottomAnchor, constant: 16),
            messageLabel.leadingAnchor.constraint(equalTo: containerBox.leadingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: containerBox.trailingAnchor, constant: -12)
        ])
    }
    
    // Dynamic access hooks to present/remove loading bounds overlays inside target ViewControllers viewport frames
    func show(on viewController: UIViewController) {
        self.frame = viewController.view.bounds
        viewController.view.addSubview(self)
        spinner.startAnimating()
    }
    
    func hide() {
        spinner.stopAnimating()
        self.removeFromSuperview()
    }
}
