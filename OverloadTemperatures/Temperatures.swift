//
//  Temperatures.swift
//  OverloadTemperatures
//
//  Created by Peter Huber on 2022-12-16.
//

import Foundation

struct Temperatures {
    
    // Temperature-dependent values of the struct are based on this temperature
    var referenceTemperature:Double
    
    var bottomFluidTemperature:Double
    
    var averageFluidTemperatureInCoolingDucts:Double
    var averageFluidTemperatureInTankAndRads:Double
    var averageWindingTemperature:Double
    
    var topFluidTemperatureInCoolingDucts:Double
    var topFluidTemperatureInTankAndRads:Double
    var hotSpotFluidTemperature:Double
    
    var hotSpotWindingTemperature:Double
    
    
}
