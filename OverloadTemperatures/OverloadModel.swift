//
//  OverloadModel.swift
//  OverloadTemperatures
//
//  Created by Peter Huber (Huberis Technologies Inc.) on 2022-12-16.
//

import Foundation

class OverloadModel {
    
    // We define two different kva bases because the BASIC program in C57.91 does that (needed for testing). This is probably useless for a manufacturer
    // kVA used for tested (or calculated) temperatures. (NOTE: This is also the "rated" kVA - the losses need to be corrected to this kVA in the routines that require "rated" losses)
    let kvaBaseForTemperatures:Double
    // kVA used for tested (or calculated) losses
    let kvaBaseForLoss:Double
    
    // The kVA used as the base for overload calculations
    let kVABaseForOverLoad:Double
    
    // cooling mode that the overload calculations will be done with (corresponds to kVABaseForOverLoad)
    let coolingMode:C57_91_CoolingType
    
    // fluid type
    let fluidType:C57_91_FluidType
    
    // winding conductor
    let conductorType:C57_91_ConductorType
    
    // tested or calculated temperatures at kvaBaseForTemperatures ("rated")
    var testedTemperatures:Temperatures
    // tested or calculated losses at kvaBaseForLoss
    var testedLosses:Losses
    
    struct MaxTemp {
        
        let temp:Double
        
        // time in minutes
        let time:Double
    }
    
    var maxHotspot:MaxTemp = MaxTemp(temp: -100.0, time: -1.0)
    var maxAverageOil:MaxTemp = MaxTemp(temp: -100.0, time: -1.0)
    
    var xExponent:Double? = nil
    var yExponent:Double? = nil
    var zExponent:Double? = nil
    
    // all masses are in pounds
    var massOfCore:Double
    var massOfFluid:Double
    var massOfTank:Double
    var massOfWindings:Double
    
    var windingTau:Double
    // var hotspotHeightPU:Double
    
    struct SavedData {
        
        // Time in minutes after 'start'
        let time:Double
        let loadPU:Double
        let temps:Temperatures
    }
    
    var overloadData:[SavedData] = []
    let dataInterval:Double
    
    // sum of masses times specific heats
    var SumM_Cp:Double {
        
        get {
            
            return SumMCp(massOfTank, SPECIFIC_HEAT_STEEL, massOfCore, SPECIFIC_HEAT_CORESTEEL, massOfFluid, AppController.StdFluids[Int(self.fluidType.rawValue)].Cp)
        }
    }
    
    var MCp_Wdg:Double {
        
        get {
            
            return massOfWindings * AppController.StdConductors[Int(self.conductorType.rawValue)].Cp
        }
    }
    
    init(kvaBaseForTemperatures:Double, kvaBaseForLoss:Double, kVABaseForOverLoad:Double, coolingMode:C57_91_CoolingType, fluidType:C57_91_FluidType, conductorType:C57_91_ConductorType, testedTemperatures:Temperatures, testedLosses:Losses, massOfCore:Double, massOfFluid:Double, massOfTank:Double, massOfWinding:Double, windingTau:Double = 5.0, dataInterval:Double = 0.5) {
        
        self.kvaBaseForTemperatures = kvaBaseForTemperatures
        self.kvaBaseForLoss = kvaBaseForLoss
        self.kVABaseForOverLoad = kVABaseForOverLoad
        self.coolingMode = coolingMode
        self.fluidType = fluidType
        self.conductorType = conductorType
        self.testedTemperatures = testedTemperatures
        self.testedLosses = testedLosses
        self.massOfCore = massOfCore
        self.massOfFluid = massOfFluid
        self.massOfTank = massOfTank
        self.massOfWindings = massOfWinding
        self.windingTau = windingTau
        self.dataInterval = dataInterval
    }
    
    /// Do the overload calculations using the given load cycles.
    /// - Parameter loadCycles: A non-empty array of LoadCycles.
    /// - Note: The loadCycles array must start with a LoadCycle of time 0 and end with a LoadCycle that has the same ambient and load as the first LoadCycle in the array. Otherwise, the function returns without doing anything.
    /// - Parameter saveInterval: The interval (in hours) for saving temperature data
    func DoOverloadCalculations(loadCycles:[LoadCycle], saveInterval:Double, withCoreOverExcitation:Bool = false) {
        
        if loadCycles.isEmpty {
            
            DLog("loadCycles array is empty!")
            return
        }
        else if loadCycles[0].cycleStartTime != 0.0 {
            
            DLog("First load cycle mjst start at time 0!")
            return
        }
        
        let firstLoadCycle = loadCycles.first!
        let lastLoadCycle = loadCycles.last!
        if firstLoadCycle.ambient != lastLoadCycle.ambient || firstLoadCycle.puLoad != lastLoadCycle.puLoad {
            
            DLog("First and last load cycles are not the same!")
            return
        }
        
        var currentTemps:Temperatures = self.testedTemperatures
        self.maxHotspot = MaxTemp(temp: currentTemps.hotSpotWindingTemperature, time: 0.0)
        self.maxAverageOil = MaxTemp(temp: currentTemps.averageFluidTemperatureInCoolingDucts, time: 0.0)
        self.overloadData.append(SavedData(time: 0.0, loadPU: 1.0, temps: currentTemps))
        var nextDataSavedTime = saveInterval * 60.0
        
        var currentDeltaT = 0.5 // minutes
        var maxDeltaT = 0.0

        if !TestStability(true, self.coolingMode, self.windingTau, currentDeltaT, &maxDeltaT, nil, nil, nil, nil, nil, nil) {
            
            currentDeltaT = maxDeltaT
        }
        
        // lastTime and currentTime are in minutes
        var lastTime = 0.0
        var currentTime = currentDeltaT
        var currentLoadCycleIndex = 0
        // endTime is in minutes
        let endTime = lastLoadCycle.cycleStartTime * 60.0
        
        var wdgTempR = [self.testedTemperatures.averageWindingTemperature, self.testedTemperatures.hotSpotWindingTemperature]
        var oilTempR = [self.testedTemperatures.averageFluidTemperatureInCoolingDucts, self.testedTemperatures.hotSpotFluidTemperature]
        // line 1320-133 of the BASIC program says to use the average of the winding and oil temps for viscosity calcs
        //var oilViscR = [MU(self.fluidType, (wdgTempR[0] + oilTempR[0]) / 2.0), MU(self.fluidType, (wdgTempR[1] + oilTempR[1]) / 2.0)]
        let oilViscTuple = FluidViscosity(atTemps: self.testedTemperatures)
        var oilViscR = [oilViscTuple.aveVisc, oilViscTuple.hotspotVisc]
        
        while currentTime < endTime && currentLoadCycleIndex < loadCycles.count - 1 {
            
            let currentLoadCycle = loadCycles[currentLoadCycleIndex]
            // nextLoadCycleStartTime is in minutes
            let nextLoadCycleStartTime = loadCycles[currentLoadCycleIndex+1].cycleStartTime * 60.0
            
            // The BASIC program will crash if a step-change in load occurs (for the definition of a step-change, see C57.91-2011 page 83, in clause (g)) since the denominator in the slope equation will equal 0 (unless BASIC doesn't react to a divide-by-zero error, which I strongly doubt). We will set it to a very small number instead:
            let loadCycleTimeStep = max(1.0E-12, nextLoadCycleStartTime - currentLoadCycle.cycleStartTime * 60.0)
            // pu per minute
            let loadSlope = (loadCycles[currentLoadCycleIndex+1].puLoad - currentLoadCycle.puLoad) / loadCycleTimeStep
            // °C per minute
            let ambientSlope = (loadCycles[currentLoadCycleIndex+1].ambient - currentLoadCycle.ambient) / loadCycleTimeStep
            
            while currentTime < nextLoadCycleStartTime {
                
                let newTemps = CalculateTempsForLoadCycle(atTime: currentTime, lastTime: lastTime, startingTemps: currentTemps, loadCycle: currentLoadCycle, loadSlope: loadSlope, ambientSlope: ambientSlope, withCoreOverExcitation: withCoreOverExcitation)
                
                if currentTime >= nextDataSavedTime {
                    
                    self.overloadData.append(SavedData(time: currentTime, loadPU: currentLoadCycle.puLoad, temps: newTemps))
                    nextDataSavedTime += saveInterval
                }
                
                if newTemps.hotSpotWindingTemperature > self.maxHotspot.temp {
                    
                    self.maxHotspot = MaxTemp(temp: newTemps.hotSpotWindingTemperature, time: currentTime)
                }
                
                if newTemps.averageFluidTemperatureInCoolingDucts > self.maxAverageOil.temp {
                    
                    self.maxAverageOil = MaxTemp(temp: newTemps.averageFluidTemperatureInCoolingDucts, time: currentTime)
                }
                
                currentTemps = newTemps
                
                var wdgTemp1 = [currentTemps.averageWindingTemperature, currentTemps.hotSpotWindingTemperature]
                var oilTemp1 = [currentTemps.averageFluidTemperatureInCoolingDucts, currentTemps.hotSpotFluidTemperature]
                // line 1320-133 of the BASIC program says to use the average of the winding and oil temps for viscosity calcs
                let oilViscTuple = FluidViscosity(atTemps: currentTemps)
                var oilVisc1 = [oilViscTuple.aveVisc, oilViscTuple.hotspotVisc]
                
                if !TestStability(false, self.coolingMode, self.windingTau, currentDeltaT, &maxDeltaT, &wdgTemp1, &wdgTempR, &oilTemp1, &oilTempR, &oilVisc1, &oilViscR) {
                    
                    currentDeltaT = maxDeltaT
                }
                
                lastTime = currentTime
                currentTime += currentDeltaT
            }
            
            currentLoadCycleIndex += 1
            
        }
    }
    
    /// Calculate the new temperatures for the next time interval
    /// - Parameter atTime:the time at which to calculate new temperatures, in minutes since the start of the simulation (corresponds to t2 in the standard)
    /// - Parameter lastTime: the time at which the last set of temperatures was calculated, in minutes since the start of the simulation
    /// - Parameter startingTemps: the temperatures calculated at 'lastTime'
    /// - Parameter loadCycle: the current LoadCycle
    /// - Parameter loadSlope: the slope of the line between the load at loadCycle and the load at the next LoadCycle, in pu/minute
    /// - Parameter ambientSlople: the slope of the line between the load at loadCycle and the load at the next LoadCycle, in °C/minute
    /// - Parameter withCoreOverExcitation: if true, use the  core losses with core overexcitation, otherwise normal core losses
    /// - Returns: The temperatures after the time interval
    func CalculateTempsForLoadCycle(atTime:Double, lastTime:Double, startingTemps:Temperatures, loadCycle:LoadCycle, loadSlope:Double, ambientSlope:Double,  withCoreOverExcitation:Bool = false) -> Temperatures {
        
        var endingTemps:Temperatures = Temperatures()
        
        // BASIC program uses PL as the variable name for the "PU Load" instead of the more familiar "K", which we use here
        let currentK = loadCycle.puLoad + loadSlope * (atTime - loadCycle.cycleStartTime * 60.0)
        let endingAmbient = startingTemps.ambientTemperature + ambientSlope * (atTime - loadCycle.cycleStartTime * 60.0)
        
        // Get the heat generated by the windings
        let lossK = currentK * self.kVABaseForOverLoad / self.kvaBaseForLoss
        let corrLoss = self.testedLosses.LossesAtLoadAndTemperature(K: lossK, newTemp: startingTemps.averageWindingTemperature)
        let heatGeneratedByWdgs = (atTime - lastTime) * corrLoss.windingLoss
        let ratedLoss = self.testedLosses.LossesAtLoadFactor(K: self.kVABaseForOverLoad / self.kvaBaseForLoss)
        
        var heatLostByWdgs = 0.0
        if startingTemps.averageWindingTemperature > startingTemps.averageFluidTemperatureInCoolingDucts {
            
            heatLostByWdgs = QLOST_W(self.coolingMode, ratedLoss.windingEddyLoss, ratedLoss.windingResistiveLoss, startingTemps.averageFluidTemperatureInCoolingDucts, self.testedTemperatures.averageFluidTemperatureInCoolingDucts, startingTemps.averageWindingTemperature, self.testedTemperatures.averageWindingTemperature, atTime - lastTime, FluidViscosity(atTemps: startingTemps).aveVisc, FluidViscosity(atTemps: self.testedTemperatures).aveVisc)
        }
        
        // line 1760-1770: update average oil temp
        let endingAveWdgTemp = Theta_W_2(heatGeneratedByWdgs, heatLostByWdgs, self.MCp_Wdg, max(startingTemps.averageWindingTemperature, startingTemps.bottomFluidTemperature))
        
        let X:Double = self.xExponent == nil ? AppController.X[Int(self.coolingMode.rawValue)] : self.xExponent!
        // line 1780: update rise of top oil over bottom oil
        let endingTopOverBottomRise = Delta_Theta_DOoverBO(heatLostByWdgs, X, atTime - lastTime, corrLoss.windingResistiveLoss, corrLoss.windingEddyLoss, self.testedTemperatures.topFluidTemperatureInCoolingDucts, self.testedTemperatures.bottomFluidTemperature)
        
        // line 1790: update the average and top oil in the ducts
        var endingTopOilInDuctsTemp = startingTemps.bottomFluidTemperature + endingTopOverBottomRise
        let endingAverageOilInDuctsTemp = (startingTemps.bottomFluidTemperature + endingTopOilInDuctsTemp) / 2.0
        
        // line 1800: update the temperature of oil adjacent to the hotspot, but then // line 1810: If (FluidTempAtTopOfDuct + 0.1)<TopFluidTempInTankAndRads then set TempOfOilAdjacentToHotSpot to TopFluidTempInTankAndRads. This looks like a fudge to make sure that the temperature of oil adjacent to the hotspot is at least as high as the top oil in the tank (probably to avoid it going too low during low load conditions).
        let endingOilAdjacentToHotpsotTemp = (endingTopOilInDuctsTemp + 0.1) < startingTemps.topFluidTemperatureInTankAndRads ? startingTemps.topFluidTemperatureInTankAndRads : startingTemps.bottomFluidTemperature + testedTemperatures.hotSpotLocationPU * endingTopOverBottomRise
        
        // Line 1820-1830: If hotspot temp is less than average winding temp and temp of oil adjacent to hotspot, set it to the higher of the two
        let fixedHotspotTemp = max(startingTemps.hotSpotWindingTemperature, endingAveWdgTemp, endingOilAdjacentToHotpsotTemp)
        
        // Line 1840: Calculate heat generated at hot spot
        let corrHsLoss = self.testedLosses.LossesAtLoadAndTemperature(K: lossK, newTemp: fixedHotspotTemp)
        let heatGeneratedByHotspot = (atTime - lastTime) * corrHsLoss.windingHotspotLoss
        
        // Line 1850-1890: Calculate the viscosity and heat lost for hot-spot depending on the cooling mode
        let heatLostByHotspot = QLOST_HS(self.coolingMode, ratedLoss.windingHotspotEddyLoss, ratedLoss.windingResistiveLoss, fixedHotspotTemp, self.testedTemperatures.hotSpotWindingTemperature, endingOilAdjacentToHotpsotTemp, self.testedTemperatures.hotSpotFluidTemperature, atTime - lastTime, MU(self.fluidType, (fixedHotspotTemp + endingOilAdjacentToHotpsotTemp) / 2.0), FluidViscosity(atTemps: self.testedTemperatures).hotspotVisc)
        
        // Line 1900: Calculate the winding hotspot temp
        let endingHotspotTemperature = Theta_H_2(heatGeneratedByHotspot, heatLostByHotspot, self.MCp_Wdg, startingTemps.hotSpotWindingTemperature)
        
        // Line 1910: Calculate the heat generated by the stray loss
        let heatGeneratedByStrayLoss = (atTime - lastTime) * corrLoss.strayLoss
        
        // Line 1920: Calculate heat lost by fluid to the ambient
        let Y:Double = self.yExponent == nil ? AppController.Y[Int(self.coolingMode.rawValue)] : self.yExponent!
        let heatLostToAmbient = QLOST_O(startingTemps.averageFluidTemperatureInTankAndRads, startingTemps.ambientTemperature, self.testedTemperatures.averageFluidTemperatureInTankAndRads, self.testedTemperatures.ambientTemperature, Y, ratedLoss.totalLoss(withOverExcitation: withCoreOverExcitation), atTime - lastTime)
        
        // Line 1930-1960: Calculate heat generated by core (the method depends on whether or not we are considering core overexcitation)
        let heatGeneratedByCore = (atTime - lastTime) * (withCoreOverExcitation ? ratedLoss.coreLoss : ratedLoss.coreLossWithOverexcitation)
        
        // Line 1970: Calculate average fluid temp in tank & rads
        let endingAverageOilInTankAndRadsTemp = Theta_AO_2(heatLostByWdgs, heatGeneratedByStrayLoss, heatGeneratedByCore, heatLostToAmbient, startingTemps.averageFluidTemperatureInTankAndRads, self.SumM_Cp)
        
        let Z:Double = self.zExponent == nil ? AppController.Z[Int(self.coolingMode.rawValue)] : self.zExponent!
        // Line 1980: Calculate temp rise of fluid at top of tank & rads over bottom fluid
        let endingTopOilRiseOverBottomOilInTankAndRads = Delta_Theta_ToverB(heatLostToAmbient, ratedLoss.totalLoss(withOverExcitation: withCoreOverExcitation), atTime - lastTime, Z, self.testedTemperatures.topFluidTemperatureInTankAndRads, self.testedTemperatures.bottomFluidTemperature)
        
        // Line 1990-2000: Calculate top & bottom fluid temp in tank & rads. If bottom oil is less than ambient, set it to the ambient.
        let endingTopOilTemperature = Theta_TO(endingAverageOilInTankAndRadsTemp, endingTopOilRiseOverBottomOilInTankAndRads)
        let endingBottomOilTemperature = max(endingAmbient, Theta_BO(endingAverageOilInTankAndRadsTemp, endingTopOilRiseOverBottomOilInTankAndRads))
        
        // Line 2010: If the fluid temp at the top of the duct is less than fluid temp at the bottom, set it to the temp at the bottom
        endingTopOilInDuctsTemp = max(endingTopOilInDuctsTemp, endingBottomOilTemperature)
        
        return endingTemps
    }
    
    /// Get the oil viscosity at the average temperature and hotspot location
    /// - Parameter atTemps: the temperatures at which to do the calculation
    /// - Returns: An tuple of Double, where the first element is the average viscosity and the second is the viscosity at the hotspot
    func FluidViscosity(atTemps:Temperatures) -> (aveVisc:Double, hotspotVisc:Double) {
        
        let wdgTemp = [atTemps.averageWindingTemperature, atTemps.hotSpotWindingTemperature]
        let oilTemp = [atTemps.averageFluidTemperatureInCoolingDucts, atTemps.hotSpotFluidTemperature]
        
        return (MU(self.fluidType, (wdgTemp[0] + oilTemp[0]) / 2.0), MU(self.fluidType, (wdgTemp[1] + oilTemp[1]) / 2.0))
    }
    
}
