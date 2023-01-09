//
//  AppController.swift
//  OverloadTemperatures
//
//  Created by Peter Huber on 2022-12-12.
//

import Cocoa

class AppController: NSObject {
    
    var model:OverloadModel? = nil
    
    // Swift converts fixed-number arrays to tuples, which is kind of useless. When this class is initialized, we will fill these arrays
    static var StdConductors:[C57_91_ConductorCharacteristics] = []
    static var StdFluids:[C57_91_FluidCharacteristics] = []
    
    // Do the same with the exponents
    static var X:[Double] = []
    static var Y:[Double] = []
    static var Z:[Double] = []
    
    override func awakeFromNib() {
        
        let (copper, aluminum) = C57_91_StandardConductors
        AppController.StdConductors = [copper, aluminum]
        
        let (oil, silicon, hthc) = C57_91_StandardFluids
        AppController.StdFluids = [oil, silicon, hthc]
        
        var (onan, onaf, ofaf, odaf) = C57_91_X
        AppController.X = [onan, onaf, ofaf, odaf]
        (onan, onaf, ofaf, odaf) = C57_91_Y
        AppController.Y = [onan, onaf, ofaf, odaf]
        (onan, onaf, ofaf, odaf) = C57_91_Z
        AppController.Z = [onan, onaf, ofaf, odaf]
    }

    @IBAction func handle_C57_91_Demo(_ sender: Any) {
                
        let loss = Losses(conductorType: .CU, referenceTemperature: 75.0, coreLoss: 36986.0, coreLossWithOverexcitation: 36986.0, windingResistiveLoss: 51690, windingEddyLoss: 0.0, windingHotspotEddyLossPU: 0.0, strayLoss: 21078.0)
        
        // let temperature = Temperatures(ambientTemperature: 20.0, averageWdgTempRise: 63.0, hotspotWdgTempRise: 80.0, hotSpotLocationPU: 1.0, topOilRise: 55.0, bottomOilRise: 25.0)
        let temperature = Temperatures(ambientTemperature: 30.0, ratedAverageWdgTempRise: 65.0, averageWdgTempRise: 63.0, hotspotWdgTempRise: 80.0, hotSpotLocationPU: 1.0, topOilRiseInDucts: 55.0, topOilRiseInTankAndRads: 55.0, bottomOilRise: 25.0)
        
        let ratedLoss = loss.LossesAtLoadAndTemperature(K: 52267.0 / 28000.0, newTemp: 95.0)
        
        // The example in the standard only has the c/c weight, which we need to split into core and winding masses. We use the strange method of calculating MwCpw, then dividing by Cpw to come up with Mw. Of course, we will never need to do this...
        let massCoreAndCoil = 75600.0
        let windingTimeConstant = 5.0 // minutes
        let MwCpw = MCp_W(ratedLoss.windingResistiveLoss, ratedLoss.windingEddyLoss, windingTimeConstant, temperature.averageFluidTemperatureInCoolingDucts, temperature.averageWindingTemperature)
        
        let Cpw = AppController.StdConductors[Int(C57_91_ConductorType.CU.rawValue)].Cp
        let massWdg = MwCpw / Cpw
        let massCore = massCoreAndCoil - massWdg
        let massOfFluid = 4910.0 * 231 * 0.031621
        
        let model = OverloadModel(kvaBaseForTemperatures: 52267.0, kvaBaseForLoss: 28000.0, kVABaseForOverLoad: 52267.0, coolingMode: .ONAF, fluidType: .MINERAL_OIL, conductorType: .CU, testedTemperatures: temperature, initialTemperatures: nil, testedLosses: loss, massOfCore: massCore, massOfFluid: massOfFluid, massOfTank: 31400, massOfWinding: massWdg)
        
        // create an array of load cycles
        let loadCycles:[LoadCycle] = [LoadCycle(cycleStartTime: 0.0, ambient: 30.0, puLoad: 0.73), LoadCycle(cycleStartTime: 1.0, ambient: 29.5, puLoad: 0.64), LoadCycle(cycleStartTime: 6.0, ambient: 28.2, puLoad: 0.56), LoadCycle(cycleStartTime: 7.0, ambient: 29.8, puLoad: 0.62), LoadCycle(cycleStartTime: 10.0, ambient: 35.9, puLoad: 0.88), LoadCycle(cycleStartTime: 13.0, ambient: 39.6, puLoad: 1.03), LoadCycle(cycleStartTime: 14.0, ambient: 40.0, puLoad: 1.07), LoadCycle(cycleStartTime: 15.0, ambient: 40.0, puLoad: 1.1), LoadCycle(cycleStartTime:16.0, ambient: 39.6, puLoad: 1.1), LoadCycle(cycleStartTime: 18.0, ambient: 36.8, puLoad: 1.04), LoadCycle(cycleStartTime: 21.0, ambient: 32.5, puLoad: 0.88), LoadCycle(cycleStartTime: 24.0, ambient: 30.0, puLoad: 0.73)]
        
        let result = model.DoOverloadCalculations(loadCycles: loadCycles, saveInterval: 0.5)
        
        print(model.OutputAsString())
        
        // print("Max hotspot temp of \(result.maxWdgHotspot.temp)°C occurs at \(result.maxWdgHotspot.time / 60.0) hours")
    }
    
    @IBAction func handleT159_Summer(_ sender: Any) {
        
        let loss = Losses(conductorType: .CU, referenceTemperature: 85.0, coreLoss: 4809.0, coreLossWithOverexcitation: 4809.0, windingResistiveLoss: 12360 + 15169, windingEddyLoss: 470 + 303, windingHotspotEddyLossPU: 0.061, strayLoss: 1205)
        
        let testAmb = 20.0
        let temperature = Temperatures(ambientTemperature: testAmb, ratedAverageWdgTempRise: 65.0, averageWdgTempRise: 58.6, hotspotWdgTempRise: 70.6, hotSpotLocationPU: 1.0, topOilRiseInDucts: 56.1, topOilRiseInTankAndRads: 56.1, bottomOilRise: 33.7)
        
        let model = OverloadModel(kvaBaseForTemperatures: 6000, kvaBaseForLoss: 6000, kVABaseForOverLoad: 6000, coolingMode: .ONAN, fluidType: .MINERAL_OIL, conductorType: .CU, testedTemperatures: temperature, initialTemperatures: nil, testedLosses: loss, massOfCore: 11627, massOfFluid: 5321 * 2.2, massOfTank: 7000 * 2.2, massOfWinding: 3630, dataInterval: 0.25)
        
        let loadCycles:[LoadCycle] = [LoadCycle(cycleStartTime: 0.0, ambient: testAmb, puLoad: 1.0), LoadCycle(cycleStartTime: 0.5 / 60, ambient: 30.0, puLoad: 1.0), LoadCycle(cycleStartTime: 12.0, ambient: 30.0, puLoad: 1.0), LoadCycle(cycleStartTime: 12.0, ambient: 30.0, puLoad: 1.15), LoadCycle(cycleStartTime: 20.0, ambient: 30.0, puLoad: 1.15), LoadCycle(cycleStartTime: 20.0, ambient: 30.0, puLoad: 1.22), LoadCycle(cycleStartTime: 24.0, ambient: 30.0, puLoad: 1.22), LoadCycle(cycleStartTime: 24.0, ambient: testAmb, puLoad: 1.0)]
        
        let result = model.DoOverloadCalculations(loadCycles: loadCycles, saveInterval: 0.25)
        
        print(model.OutputAsString())
    }
    
    @IBAction func handleT159_Winter(_ sender: Any) {
        
        let loss = Losses(conductorType: .CU, referenceTemperature: 85.0, coreLoss: 4809.0, coreLossWithOverexcitation: 4809.0, windingResistiveLoss: 12360 + 15169, windingEddyLoss: 470 + 303, windingHotspotEddyLossPU: 0.061, strayLoss: 1205)
        
        let testAmb = -20.0
        let temperature = Temperatures(ambientTemperature: testAmb, ratedAverageWdgTempRise: 65.0, averageWdgTempRise: 58.6, hotspotWdgTempRise: 70.6, hotSpotLocationPU: 1.0, topOilRiseInDucts: 56.1, topOilRiseInTankAndRads: 56.1, bottomOilRise: 33.7)
        
        let model = OverloadModel(kvaBaseForTemperatures: 6000, kvaBaseForLoss: 6000, kVABaseForOverLoad: 6000, coolingMode: .ONAN, fluidType: .MINERAL_OIL, conductorType: .CU, testedTemperatures: temperature, initialTemperatures: nil, testedLosses: loss, massOfCore: 11627, massOfFluid: 5321 * 2.2, massOfTank: 7000 * 2.2, massOfWinding: 3630)
        
        let loadCycles:[LoadCycle] = [LoadCycle(cycleStartTime: 0.0, ambient: testAmb, puLoad: 1.0), LoadCycle(cycleStartTime: 0.5 / 60, ambient: -20.0, puLoad: 1.35), LoadCycle(cycleStartTime: 12.0, ambient: -20.0, puLoad: 1.35), LoadCycle(cycleStartTime: 12.0, ambient: -20.0, puLoad: 1.48), LoadCycle(cycleStartTime: 20.0, ambient: -20.0, puLoad: 1.48), LoadCycle(cycleStartTime: 20.0, ambient: -20.0, puLoad: 1.5), LoadCycle(cycleStartTime: 24.0, ambient: -20.0, puLoad: 1.5), LoadCycle(cycleStartTime: 24.0, ambient: testAmb, puLoad: 1.0)]
        
        let result = model.DoOverloadCalculations(loadCycles: loadCycles, saveInterval: 0.25)
        
        print(model.OutputAsString())
    }
    
}
