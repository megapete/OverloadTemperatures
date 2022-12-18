//
//  Losses.swift
//  OverloadTemperatures
//
//  Created by Peter Huber on 2022-12-16.
//

import Foundation

struct Losses {
    
    var conductorType:C57_91_ConductorType
    
    var referenceTemperature:Double
    
    var coreLoss:Double
    var coreLossWithOverexcitation:Double = 0.0
    var windingResistiveLoss:Double
    var windingEddyLoss:Double
    var windingAvergeEddyLossPU:Double {
        
        get {
            
            return self.windingEddyLoss / self.windingResistiveLoss
        }
        
        set {
            
            self.windingEddyLoss = newValue * self.windingResistiveLoss
        }
    }
    var windingHotspotEddyLossPU:Double
    var strayLoss:Double
    
    
    // wrapper for C57.91 equation G.5)
    func TemperatureCorrectionFactor(newTemp:Double) -> Double {
        
        // Set the correct resistance factor depending on the conductor
        let condFactor = self.conductorType == CU ? 234.5 : 225.0
        
        // call the appropriate C57.91 function
        return Kw(self.referenceTemperature, newTemp, condFactor)
    }
    
    // Get the corrected winding resistive loss at the given temperature
    func correctedWdgResistiveLoss(temperature:Double) -> Double {
        
        return self.windingResistiveLoss * self.TemperatureCorrectionFactor(newTemp: temperature)
    }
    
    // Get the corrected winding eddy loss at the given temperature
    func correctedWdgEddyLoss(temperature:Double) -> Double {
        
        return self.windingEddyLoss / self.TemperatureCorrectionFactor(newTemp: temperature)
    }
    
    // Get the corrected winding eddy loss at the given temperature
    func correctedWdgStrayLoss(temperature:Double) -> Double {
        
        return self.strayLoss / self.TemperatureCorrectionFactor(newTemp: temperature)
    }
    
    // Get the corrected total winding loss at the given temperature
    func correctedWdgTotalLoss(temperature:Double) -> Double {
        
        let corrFact = self.TemperatureCorrectionFactor(newTemp: temperature)
        
        return self.windingResistiveLoss * corrFact + self.windingEddyLoss / corrFact
    }
}
