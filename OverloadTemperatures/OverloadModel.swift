//
//  OverloadModel.swift
//  OverloadTemperatures
//
//  Created by Peter Huber on 2022-12-16.
//

import Foundation

class OverloadModel {
    
    // rated load in kVA
    let ratedLoad:Double
    // cooling mode that the overload calculations will be done with
    let coolingMode:C57_91_CoolingType
    
    var tempsAtRatedLoad:Temperatures
    var lossesAtRatedLoad:Losses
    
    var maxOverloadTemps:Temperatures
    
    // all masses are in pounds
    var massOfCore:Double
    var massOfFluid:Double
    var massOfTank:Double
    var massOfWindings:Double
    
    init(ratedLoad:Double, coolingMode:C57_91_CoolingType, tempsAtRatedLoad:Temperatures, lossesAtRatedLoad:Losses, massOfCore:Double, massOfFluid:Double, massOfTank:Double, massOfWinding:Double) {
        
        self.ratedLoad = ratedLoad
        self.coolingMode = coolingMode
        self.tempsAtRatedLoad = tempsAtRatedLoad
        self.lossesAtRatedLoad = lossesAtRatedLoad
        self.maxOverloadTemps = Temperatures()
        self.massOfCore = massOfCore
        self.massOfFluid = massOfFluid
        self.massOfTank = massOfTank
        self.massOfWindings = massOfWinding
    }
    
}
