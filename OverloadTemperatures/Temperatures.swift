//
//  Temperatures.swift
//  OverloadTemperatures
//
//  Created by Peter Huber on 2022-12-16.
//

import Foundation

struct Temperatures {
    
    var ambientTemperature:Double
    
    var ratedAverageWindingRise:Double
    
    var ratedAverageWindingTemperature:Double {
        
        get {
            return self.ambientTemperature + self.ratedAverageWindingRise
        }
    }
    
    var bottomFluidTemperature:Double
    var topFluidTemperatureInCoolingDucts:Double
    var topFluidTemperatureInTankAndRads:Double
    
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
    var hotSpotWindingTemperature:Double
    
    // The height (in PU) of the hotspot with respect to the bottom of the coil (1 = pyhsical top of the coil)
    var hotSpotLocationPU:Double
    
    var hotSpotFluidTemperature:Double {
        
        return self.bottomFluidTemperature + Delta_Theta_WOoverBO(self.hotSpotLocationPU, self.bottomFluidTemperature, self.topFluidTemperatureInCoolingDucts)
    }
    
    // A couple of enums to make it easier to quickly create "standard" temp profiles.
    enum StandardTemp {
    
        case std_55_70
        case std_65_80
    }
    
    // A more useful initializer for our use (uses temp rises and ambient to calculate temps)
    init(ambientTemperature:Double, ratedAverageWdgTempRise:Double, averageWdgTempRise:Double, hotspotWdgTempRise:Double, hotSpotLocationPU:Double, topOilRiseInDucts:Double, topOilRiseInTankAndRads:Double, bottomOilRise:Double) {
        
        self.ambientTemperature = ambientTemperature
        self.ratedAverageWindingRise = ratedAverageWdgTempRise
        self.bottomFluidTemperature = ambientTemperature + bottomOilRise
        self.topFluidTemperatureInCoolingDucts = ambientTemperature + topOilRiseInDucts
        self.topFluidTemperatureInTankAndRads = ambientTemperature + topOilRiseInTankAndRads
        self.hotSpotLocationPU = hotSpotLocationPU
        self.averageWindingTemperature = ambientTemperature + averageWdgTempRise
        self.hotSpotWindingTemperature = ambientTemperature + hotspotWdgTempRise
    }
    
    // Another useful initilaizer, this one using actual tempertatures instead of rises (except for the rated value of average winding temp rise)
    init(ambientTemperature:Double, ratedAverageWdgTempRise:Double, averageWdgTemp:Double, hotspotWdgTemp:Double, hotSpotLocationPU:Double, topOilTempInDucts:Double, topOilTempInTankAndRads:Double, bottomOilTemp:Double) {
        
        self.ambientTemperature = ambientTemperature
        self.ratedAverageWindingRise = ratedAverageWdgTempRise
        self.bottomFluidTemperature = bottomOilTemp
        self.topFluidTemperatureInCoolingDucts = topOilTempInDucts
        self.topFluidTemperatureInTankAndRads = topOilTempInTankAndRads
        self.hotSpotLocationPU = hotSpotLocationPU
        self.averageWindingTemperature = averageWdgTemp
        self.hotSpotWindingTemperature = hotspotWdgTemp
    }
    
    // A way to set all the temperatures to the same value (useful for setting a variable that tracks max temps, hint, hint)
    init(commonTemp:Double) {
        
        self.ambientTemperature = commonTemp
        self.ratedAverageWindingRise = commonTemp
        self.bottomFluidTemperature = commonTemp
        self.topFluidTemperatureInCoolingDucts = commonTemp
        self.topFluidTemperatureInTankAndRads = commonTemp
        self.hotSpotLocationPU = 1.0
        self.averageWindingTemperature = commonTemp
        self.hotSpotWindingTemperature = commonTemp
    }
    
    // And apparently because we have defined other inits, we have to explicitly create the "default" initializer
    init(ambientTemperature:Double = 20.0, ratedAverageWdgTempRise:Double = 65.0, bottomFluidTemperature:Double = 20.0, averageWindingTemperature:Double = 20.0, topFluidTemperature:Double = 20.0,  hotSpotWindingTemperature:Double = 20.0, hotSpotLocationPU:Double = 1.0) {
        
        self.ambientTemperature = ambientTemperature
        self.ratedAverageWindingRise = ratedAverageWdgTempRise
        self.bottomFluidTemperature = bottomFluidTemperature
        self.topFluidTemperatureInCoolingDucts = topFluidTemperature
        self.topFluidTemperatureInTankAndRads = topFluidTemperature
        self.hotSpotLocationPU = hotSpotLocationPU
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
        self.ratedAverageWindingRise = averageWdgRise
        self.topFluidTemperatureInTankAndRads = self.ambientTemperature + topFluidRise
        self.topFluidTemperatureInCoolingDucts = self.topFluidTemperatureInTankAndRads
        self.hotSpotLocationPU = 1.0
        self.bottomFluidTemperature = self.topFluidTemperatureInTankAndRads - topToBottomDiff
    }
}
