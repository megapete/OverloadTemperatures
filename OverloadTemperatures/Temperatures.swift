//
//  Temperatures.swift
//  OverloadTemperatures
//
//  Created by Peter Huber on 2022-12-16.
//

import Foundation

struct Temperatures {
    
    var ambientTemperature:Double = 20.0
    
    var bottomFluidTemperature:Double = 20.0
    
    var averageFluidTemperatureInCoolingDucts:Double = 20.0
    var averageFluidTemperatureInTankAndRads:Double = 20.0
    var averageWindingTemperature:Double = 20.0
    
    var topFluidTemperatureInCoolingDucts:Double = 20.0
    var topFluidTemperatureInTankAndRads:Double = 20.0
    var hotSpotFluidTemperature:Double = 20.0
    
    var hotSpotWindingTemperature:Double = 20.0
    
    // A couple of enums to make it easier to quickly create "standard" temp profiles.
    enum StandardTemp {
    
        case std_55_70
        case std_65_80
    }
    
    // This is needed to allow defaut initialization
    init() {
        
    }
    
    // Simple init call to create a dummy temperature profile. The radiator temperature fall (from top to bottom) is arbitrarily set to 20C. The ambient is assumed to be the default (20.0).
    init(usingStd:StandardTemp) {
        
        var averageWdgRise = 65.0
        var hotSpotWdgRise = 80.0
        var topFluidRise = 65.0
        let topToBottomDiff = 20.0
        
        switch usingStd {
            
        case .std_55_70:
            
            averageWdgRise = 55.0
            hotSpotWdgRise = 70.0
            topFluidRise = 55.0
            
        case .std_65_80:
            
            averageWdgRise = 65.0
            hotSpotWdgRise = 80.0
            topFluidRise = 65.0
        }
        
        self.hotSpotWindingTemperature = self.ambientTemperature + hotSpotWdgRise
        self.averageWindingTemperature = self.ambientTemperature + averageWdgRise
        self.topFluidTemperatureInTankAndRads = self.ambientTemperature + topFluidRise
        self.topFluidTemperatureInCoolingDucts = self.topFluidTemperatureInTankAndRads
        self.hotSpotFluidTemperature = topFluidTemperatureInCoolingDucts
        self.bottomFluidTemperature = self.topFluidTemperatureInTankAndRads - 20.0
        self.averageFluidTemperatureInTankAndRads = (self.topFluidTemperatureInTankAndRads + self.bottomFluidTemperature) / 2.0
        self.averageFluidTemperatureInCoolingDucts = (self.topFluidTemperatureInCoolingDucts + self.bottomFluidTemperature) / 2.0
    }
}
