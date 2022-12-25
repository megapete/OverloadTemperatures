//
//  OverloadModel.swift
//  OverloadTemperatures
//
//  Created by Peter Huber (Huberis Technologies Inc.) on 2022-12-16.
//

import Foundation

class OverloadModel {
    
    // We define two different kva bases because the BASIC program in C57.91 does that (needed for testing). This is probably useless for a manufacturer
    // kVA used for tested (or calculated) temperatures
    let kvaBaseForTemperatures:Double
    // kVA used for tested (or calculated) losses
    let kvaBaseForLoss:Double
    
    // The kVA used as the base for overload calculations
    let kVABaseForOverLoad:Double
    
    // cooling mode that the overload calculations will be done with (corresponds to kVABaseForOverLoad)
    let coolingMode:C57_91_CoolingType
    
    // fluid type
    let fluidType:C57_91_FluidType
    
    // tested or calculated temperatures at kvaBaseForTemperatures
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
    
    init(kvaBaseForTemperatures:Double, kvaBaseForLoss:Double, kVABaseForOverLoad:Double, coolingMode:C57_91_CoolingType, fluidType:C57_91_FluidType, testedTemperatures:Temperatures, testedLosses:Losses, massOfCore:Double, massOfFluid:Double, massOfTank:Double, massOfWinding:Double, windingTau:Double = 5.0, dataInterval:Double = 0.5) {
        
        self.kvaBaseForTemperatures = kvaBaseForTemperatures
        self.kvaBaseForLoss = kvaBaseForLoss
        self.kVABaseForOverLoad = kVABaseForOverLoad
        self.coolingMode = coolingMode
        self.fluidType = fluidType
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
        
        var currentTime = currentDeltaT
        var currentLoadCycleIndex = 0
        // var nextLoadCycleIndex = 1
        let endTime = lastLoadCycle.cycleStartTime * 60.0
        
        var wdgTempR = [self.testedTemperatures.averageWindingTemperature, self.testedTemperatures.hotSpotWindingTemperature]
        var oilTempR = [self.testedTemperatures.averageFluidTemperatureInCoolingDucts, self.testedTemperatures.hotSpotFluidTemperature]
        // line 1320-133 of the BASIC program says to use the average of the winding and oil temps for viscosity calcs
        var oilViscR = [MU(self.fluidType, (wdgTempR[0] + oilTempR[0]) / 2.0), MU(self.fluidType, (wdgTempR[1] + oilTempR[1]) / 2.0)]
        
        while currentTime < endTime && currentLoadCycleIndex < loadCycles.count - 1 {
            
            let currentLoadCycle = loadCycles[currentLoadCycleIndex]
            let nextLoadCycleStartTime = loadCycles[currentLoadCycleIndex+1].cycleStartTime * 60.0
            
            let loadSlope = (loadCycles[currentLoadCycleIndex+1].puLoad - currentLoadCycle.puLoad) / (nextLoadCycleStartTime - currentLoadCycle.cycleStartTime)
            
            let ambientSlope = (loadCycles[currentLoadCycleIndex+1].ambient - currentLoadCycle.ambient) / (nextLoadCycleStartTime - currentLoadCycle.cycleStartTime)
            
            while currentTime < nextLoadCycleStartTime {
                
                let newTemps = CalculateTempsForLoadCycle(atTime: currentTime, startingTemps: currentTemps, loadCycle: currentLoadCycle, loadSlope: loadSlope, ambientSlope: ambientSlope, withCoreOverExcitation: withCoreOverExcitation)
                
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
                var oilVisc1 = [MU(self.fluidType, (wdgTemp1[0] + oilTemp1[0]) / 2.0), MU(self.fluidType, (wdgTemp1[1] + oilTemp1[1]) / 2.0)]
                
                if !TestStability(false, self.coolingMode, self.windingTau, currentDeltaT, &maxDeltaT, &wdgTemp1, &wdgTempR, &oilTemp1, &oilTempR, &oilVisc1, &oilViscR) {
                    
                    currentDeltaT = maxDeltaT
                }
                
                currentTime += currentDeltaT
            }
            
            currentLoadCycleIndex += 1
            
        }
    }
    
    func CalculateTempsForLoadCycle(atTime:Double, startingTemps:Temperatures, loadCycle:LoadCycle, loadSlope:Double, ambientSlope:Double,  withCoreOverExcitation:Bool = false) -> Temperatures {
        
        var endingTemps:Temperatures = Temperatures()
        
        let currentK = loadCycle.puLoad + loadSlope * (atTime - loadCycle.cycleStartTime)
        let currentAmbient = endingTemps.ambientTemperature + ambientSlope * (atTime - loadCycle.cycleStartTime)
        
        
        
        return endingTemps
    }
}
