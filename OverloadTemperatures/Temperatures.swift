//
//  Temperatures.swift
//  OverloadTemperatures
//
//  Created by Peter Huber on 2022-12-16.
//

import Foundation

struct Temperatures {
    
    // Temperature-dependent values of the struct are based on this temperature
    var referenceTemperature:Double = 20.0
    
    var bottomFluidTemperature:Double = 20.0
    
    var averageFluidTemperatureInCoolingDucts:Double = 20.0
    var averageFluidTemperatureInTankAndRads:Double = 20.0
    var averageWindingTemperature:Double = 20.0
    
    var topFluidTemperatureInCoolingDucts:Double = 20.0
    var topFluidTemperatureInTankAndRads:Double = 20.0
    var hotSpotFluidTemperature:Double = 20.0
    
    var hotSpotWindingTemperature:Double = 20.0
    
    
}
