//
//  AppController.swift
//  OverloadTemperatures
//
//  Created by Peter Huber on 2022-12-12.
//

import Cocoa

class AppController: NSObject {
    
    var model:OverloadModel? = nil

    @IBAction func handle_C57_91_Demo(_ sender: Any) {
        
        let loss = Losses(conductorType: CU, referenceTemperature: 75.0, coreLoss: 36986.0, coreLossWithOverexcitation: 36986.0, windingResistiveLoss: 51690.0, windingEddyLoss: 0.0, windingHotspotEddyLossPU: 0.0, strayLoss: 21078.0)
        
        let temperature = Temperatures(ambientTemperature: 20.0, averageWdgTempRise: 63.0, hotspotWdgTempRise: 80.0, topOilRise: 55.0, bottomOilRise: 25.0)
        
        // The example in the standard only has the c/c weight, which we need to split into core and winding masses. We use the strange method of calculating MwCpw, then dividing by Cpw to come up with Mw. Of course, we will never need to do this...
        let massCoreAndCoil = 75600.0
        let windingTimeConstant = 5.0 // minutes
        let MwCpw = MCp_W(51690.0, 0.0, windingTimeConstant, temperature.averageFluidTemperatureInCoolingDucts, temperature.averageWindingTemperature)
        let StdCondChars = StandardConductors
        // well this is ugly...
        let Cpw = StdCondChars.0.Cp
        let massWdg = MwCpw / Cpw
        let massCore = massCoreAndCoil - massWdg
        
        let model = OverloadModel(kvaBaseForTemperatures: 52267.0, kvaBaseForLoss: 28000.0, coolingMode: ONAF, testedTemperatures: temperature, testedLosses: loss, massOfCore: massCore, massOfFluid: 4910.0, massOfTank: 31400, massOfWinding: massWdg)
    }
    
}
