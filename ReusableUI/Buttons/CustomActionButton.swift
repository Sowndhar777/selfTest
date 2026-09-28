import UIKit

@IBDesignable
class CustomActionButton: UIButton {
    
    // Run initialization frames when generated programmatically
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }
    
    // Run initializations configurations when loaded visually from storyboards interface structures
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureUI()
    }
    
    private func configureUI() {
        self.backgroundColor = .brandGreen
        self.layer.cornerRadius = 12
        
        // Font setup adjustments safely matching core iOS styles
        self.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        self.setTitleColor(.white, for: .normal)
        
        // Dynamic drop shadow boundaries layer parameters configuration
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 4)
        self.layer.shadowRadius = 4
        self.layer.shadowOpacity = 0.15
        self.layer.masksToBounds = false
    }
    
    // Touch tracking dynamic scaling physics interaction animation effects feedback
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.15) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.95, y: 0.95) : .identity

            }
        }
    }
}
