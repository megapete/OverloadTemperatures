//
//  OverloadModel.swift
//  OverloadTemperatures
//
//  Created by Peter Huber on 2022-12-16.
//

import Foundation

class OverloadModel {
    
    // We define two different kva bases because the BASIC program in C57.91 does that (needed for testing). This is probably useless for a manufacturer
    // kVA used for tested (or calculated) temperatures
    let kvaBaseForTemperatures:Double
    // kVA used for tested (or calculated) losses
    let kvaBaseForLoss:Double
    
    // cooling mode that the overload calculations will be done with
    let coolingMode:C57_91_CoolingType
    
    // tested or calculated temperatures at kvaBaseForTemperatures
    var testedTemperatures:Temperatures
    // tested or calculated losses at kvaBaseForLoss
    var testedLosses:Losses
    
    var maxOverloadTemps:Temperatures
    
    // all masses are in pounds
    var massOfCore:Double
    var massOfFluid:Double
    var massOfTank:Double
    var massOfWindings:Double
    
    init(kvaBaseForTemperatures:Double, kvaBaseForLoss:Double, coolingMode:C57_91_CoolingType, testedTemperatures:Temperatures, testedLosses:Losses, massOfCore:Double, massOfFluid:Double, massOfTank:Double, massOfWinding:Double) {
        
        self.kvaBaseForTemperatures = kvaBaseForTemperatures
        self.kvaBaseForLoss = kvaBaseForLoss
        self.coolingMode = coolingMode
        self.testedTemperatures = testedTemperatures
        self.testedLosses = testedLosses
        self.maxOverloadTemps = Temperatures()
        self.massOfCore = massOfCore
        self.massOfFluid = massOfFluid
        self.massOfTank = massOfTank
        self.massOfWindings = massOfWinding
    }
    
}
