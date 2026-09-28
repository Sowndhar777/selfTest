import UIKit

extension UIStoryboard {
    enum StoryboardType: String {
        case onboarding = "Onboarding"
        case auth = "Auth"
        case home = "Home"
        case detail = "RecipeDetail"
        case planner = "Planner"
        case community = "Community"
        case profile = "Profile"
    }
    
    
    static func instantiateViewController<T: UIViewController>(from type: StoryboardType, identifier: String) -> T {
        let storyboard = UIStoryboard(name: type.rawValue, bundle: nil)
        
        guard let viewController = storyboard.instantiateViewController(withIdentifier: identifier) as? T else {
            fatalError("🚨 Error: ViewController with identifier '\(identifier)' not found in \(type.rawValue).storyboard")
        }
        
        return viewController
    }
}
