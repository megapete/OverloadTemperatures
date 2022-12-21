//
//  Temperatures.swift
//  OverloadTemperatures
//
//  Created by Peter Huber on 2022-12-16.
//

import Foundation

struct Temperatures {
    
    var ambientTemperature:Double
    
    var bottomFluidTemperature:Double
    
    var averageFluidTemperatureInCoolingDucts:Double {
        
        get {
            
            return (topFluidTemperatureInCoolingDucts + bottomFluidTemperature) / 2
        }
    }
    var averageFluidTemperatureInTankAndRads:Double {
        
        get {
            
            return (topFluidTemperatureInTankAndRads + bottomFluidTemperature) / 2
        }
    }
    var averageWindingTemperature:Double
    
    var topFluidTemperatureInCoolingDucts:Double
    var topFluidTemperatureInTankAndRads:Double
    var hotSpotFluidTemperature:Double
    
    var hotSpotWindingTemperature:Double
    
    // A couple of enums to make it easier to quickly create "standard" temp profiles.
    enum StandardTemp {
    
        case std_55_70
        case std_65_80
    }
    
    // A more useful initializer for our use
    init(ambientTemperature:Double = 20.0, averageWdgTempRise:Double, hotspotWdgTempRise:Double, topOilRise:Double, bottomOilRise:Double) {
        
        self.ambientTemperature = ambientTemperature
        self.bottomFluidTemperature = ambientTemperature + bottomOilRise
        self.topFluidTemperatureInCoolingDucts = ambientTemperature + topOilRise
        self.topFluidTemperatureInTankAndRads = self.topFluidTemperatureInCoolingDucts
        self.hotSpotFluidTemperature = self.topFluidTemperatureInCoolingDucts
        self.averageWindingTemperature = ambientTemperature + averageWdgTempRise
        self.hotSpotWindingTemperature = ambientTemperature + hotspotWdgTempRise
        // self.averageFluidTemperatureInCoolingDucts = (topOilRise + bottomOilRise) / 2.0 + ambientTemperature
        // self.averageFluidTemperatureInTankAndRads = self.averageFluidTemperatureInCoolingDucts
    }
    
    // A way to set all the temperatures to the same value (useful for setting a variable that tracks max temps, hint, hint)
    init(commonTemp:Double) {
        
        self.ambientTemperature = commonTemp
        self.bottomFluidTemperature = commonTemp
        self.topFluidTemperatureInCoolingDucts = commonTemp
        self.topFluidTemperatureInTankAndRads = commonTemp
        self.hotSpotFluidTemperature = commonTemp
        self.averageWindingTemperature = commonTemp
        self.hotSpotWindingTemperature = commonTemp
    }
    
    // And apparently because we have defined other inits, we have to explicitly create the "default" initializer
    init(ambientTemperature:Double = 20.0, bottomFluidTemperature:Double = 20.0, averageWindingTemperature:Double = 20.0, topFluidTemperature:Double = 20.0,  hotSpotWindingTemperature:Double = 20.0) {
        
        self.ambientTemperature = ambientTemperature
        self.bottomFluidTemperature = bottomFluidTemperature
        self.topFluidTemperatureInCoolingDucts = topFluidTemperature
        self.topFluidTemperatureInTankAndRads = topFluidTemperature
        self.hotSpotFluidTemperature = topFluidTemperature
        // self.averageFluidTemperatureInCoolingDucts = (topFluidTemperature + bottomFluidTemperature) / 2.0
        // self.averageFluidTemperatureInTankAndRads = (topFluidTemperature + bottomFluidTemperature) / 2.0
        self.averageWindingTemperature = averageWindingTemperature
        self.hotSpotWindingTemperature = hotSpotWindingTemperature
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
        
        self.ambientTemperature = 20.0
        self.hotSpotWindingTemperature = self.ambientTemperature + hotSpotWdgRise
        self.averageWindingTemperature = self.ambientTemperature + averageWdgRise
        self.topFluidTemperatureInTankAndRads = self.ambientTemperature + topFluidRise
        self.topFluidTemperatureInCoolingDucts = self.topFluidTemperatureInTankAndRads
        self.hotSpotFluidTemperature = topFluidTemperatureInCoolingDucts
        self.bottomFluidTemperature = self.topFluidTemperatureInTankAndRads - topToBottomDiff
        // self.averageFluidTemperatureInTankAndRads = (self.topFluidTemperatureInTankAndRads + self.bottomFluidTemperature) / 2.0
        // self.averageFluidTemperatureInCoolingDucts = (self.topFluidTemperatureInCoolingDucts + self.bottomFluidTemperature) / 2.0
    }
}
