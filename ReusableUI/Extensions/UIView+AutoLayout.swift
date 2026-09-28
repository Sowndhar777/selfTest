import UIKit

extension UIView {
    // Instantly pins any view layout safely to its superview containers
    func pinToSuperviewEdges(padding: CGFloat = 0) {
        guard let superview = self.superview else { return }
        self.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            self.topAnchor.constraint(equalTo: superview.topAnchor, constant: padding),
            self.leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: padding),
            self.trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: -padding),
            self.bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -padding)
        ])
    }
    
    // Dynamic height and width absolute anchor setter
    func setDimensions(height: CGFloat, width: CGFloat) {
        self.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.heightAnchor.constraint(equalToConstant: height),
            self.widthAnchor.constraint(equalToConstant: width)
        ])
    }
}
