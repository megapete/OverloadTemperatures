//
//  OverloadModel.swift
//  OverloadTemperatures
//
//  Created by Peter Huber on 2022-12-16.
//

import Foundation

class OverloadModel {
    
    var tempsAtRatedLoad:Temperatures
    var lossesAtRatedLoad:Losses
    
    var maxOverloadTemps:Temperatures
    
    // all masses are in pounds
    var massOfCore:Double
    var massOfFluid:Double
    var massOfTank:Double
    var massOfWindings:Double
    
    
}
