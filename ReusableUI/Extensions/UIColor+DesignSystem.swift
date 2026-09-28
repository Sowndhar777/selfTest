import UIKit

extension UIColor {
    // Primary Brand Identity Colors
    static var brandGreen: UIColor {
        return UIColor(red: 46/255, green: 204/255, blue: 113/255, alpha: 1.0) // Production Fresh Green
    }
    
    static var brandDarkGreen: UIColor {
        return UIColor(red: 39/255, green: 174/255, blue: 96/255, alpha: 1.0)
    }
    
    // UI Layout Surfaces
    static var surfaceBackground: UIColor {
        return .systemBackground
    }
    
    static var secondarySurfaceBackground: UIColor {
        return .secondarySystemBackground
    }
    
    // Validation Feedback Alert Colors
    static var validationErrorRed: UIColor {
        return .systemRed
    }
    
    static var validationSuccessGreen: UIColor {
        return .systemGreen
    }
}
