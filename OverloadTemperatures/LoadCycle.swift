//
//  LoadCycle.swift
//  OverloadTemperatures
//
//  Created by Peter Huber on 2022-12-16.
//

import Foundation

struct LoadCycle {
    
    // in hours
    let cycleStartTime:Double
    // in °C
    let ambient:Double
    // as a multiple of rated load
    let puLoad:Double
}
