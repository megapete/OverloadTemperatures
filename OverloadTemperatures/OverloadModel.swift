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
    
    // tested or calculated temperatures at kvaBaseForTemperatures
    var testedTemperatures:Temperatures
    // tested or calculated losses at kvaBaseForLoss
    var testedLosses:Losses
    
    struct MaxTemp {
        
        let temp:Double
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
    var hotspotHeightPU:Double
    
    struct SavedData {
        
        let time:Double
        let loadPU:Double
        let temps:Temperatures
    }
    
    var overloadData:[SavedData] = []
    let dataInterval:Double
    
    init(kvaBaseForTemperatures:Double, kvaBaseForLoss:Double, kVABaseForOverLoad:Double, coolingMode:C57_91_CoolingType, testedTemperatures:Temperatures, testedLosses:Losses, massOfCore:Double, massOfFluid:Double, massOfTank:Double, massOfWinding:Double, windingTau:Double = 5.0, hotspotHeightPU:Double = 1.0, dataInterval:Double = 0.5) {
        
        self.kvaBaseForTemperatures = kvaBaseForTemperatures
        self.kvaBaseForLoss = kvaBaseForLoss
        self.kVABaseForOverLoad = kVABaseForOverLoad
        self.coolingMode = coolingMode
        self.testedTemperatures = testedTemperatures
        self.testedLosses = testedLosses
        self.massOfCore = massOfCore
        self.massOfFluid = massOfFluid
        self.massOfTank = massOfTank
        self.massOfWindings = massOfWinding
        self.hotspotHeightPU = hotspotHeightPU
        self.windingTau = windingTau
        self.dataInterval = dataInterval
    }
    
    /// Do the overload calculations using the given load cycles.
    /// - Parameter loadCycles: A non-empty array of LoadCycles.
    /// - Note: The loadCycles array must start with a LoadCycle of time 0 and end with a LoadCycle that has the same ambient and load as the first LoadCycle in the array. Otherwise, the function returns without doing anything.
    /// - Parameter saveInterval: The interval (in hours) for saving temperature data
    func DoOverloadCalculations(loadCycles:[LoadCycle], saveInterval:Double) {
        
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
        var lastDataSavedTime = 0.0
        self.overloadData.append(SavedData(time: lastDataSavedTime, loadPU: 1.0, temps: currentTemps))
        
        var currentDeltaT = 0.5 // minutes
        var maxDeltaT = 0.0

        if !TestStability(true, self.coolingMode, self.windingTau, currentDeltaT, &maxDeltaT, nil, nil, nil, nil, nil, nil) {
            
            currentDeltaT = maxDeltaT
        }
        
        var currentTime = 0.0
        var currentLoadCycleIndex = 0
        
        
        for nextLoadCycle in loadCycles {
            
            let newTemps = CalculateTempsForLoadCycle(startingTemps: currentTemps, loadCycle: nextLoadCycle)
            
            if newTemps.hotSpotWindingTemperature > self.maxHotspot.temp {
                
            }
            
            
        }
    }
    
    func CalculateTempsForLoadCycle(startingTemps:Temperatures, loadCycle:LoadCycle, withCoreOverExcitation:Bool = false) -> Temperatures {
        
        var endingTemps:Temperatures = Temperatures()
        
        
        
        return endingTemps
    }
}
