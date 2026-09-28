//
//  OnboardingViewModel.swift
//  selfTest
//
//  Created by sowndharrajan on 20/09/26.
//

import Foundation

// Structural data model representing individual introductory slide items
struct OnboardingSlide {
    let title: String
    let description: String
    let imageName: String // System icon representation keys (SF Symbols)
}

class OnboardingViewModel {
    
    // Core data array tracking state variables safely isolated from interface layouts
    private var slides: [OnboardingSlide] = []
    
    // Initializer maps target presentation cards matrix configurations tokens
    init() {
        loadDefaultSlides()
    }
    
    private func loadDefaultSlides() {
        slides = [
            OnboardingSlide(title: "Fresh Recipes", description: "Discover thousands of tailored high-end culinary formulas updated daily.", imageName: "fork.knife.circle.fill"),
            OnboardingSlide(title: "Smart Portion Scaler", description: "Dynamically adjust ingredient quantities parameters safely matching exact serving metrics bounds.", imageName: "scalemass.fill"),
            OnboardingSlide(title: "Weekly Log Planner", description: "Schedule meals and let automation convert layouts instantly into shopping checklists.", imageName: "calendar.badge.plus")
        ]
    }
    
    // Data stream binding validation interfaces for ViewControllers
    var numberOfSlides: Int {
        return slides.count
    }
    
    func getSlideData(at index: Int) -> OnboardingSlide {
        return slides[index]
    }
}
