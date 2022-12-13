//
//  C57_91_Functions.c
//  OverloadTemperatures
//
//  Created by Peter Huber on 2022-12-12.
//

#include "C57_91_Functions.h"
#include <math.h>

/* Function G.1: Hottest-spot temperature

 ΘH = ΘA + ΔΘBO + ΔΘWO/BO + ΔΘH/WO
 
 Where:
 ΘA is the average ambient temperature during the load cycle to be studied, °C
 ΔΘBO is the bottom fluid rise over ambient, °C
 ΔΘWO/BO is the temperature rise of oil at winding hot-spot location over bottom oil, °C
 ΔΘH/WO is the winding hot-spot temperature rise over oil next to hot-spot location, °C
 
 Returns:
 ΘH, which is the winding hottest-spot temperature, °C
 
 */
double Theta_H(double theta_A, double delta_theta_BO, double delta_theta_WOoverBO, double delta_theta_HoverWO) {
    
    double result = theta_A + delta_theta_BO + delta_theta_WOoverBO + delta_theta_HoverWO;
    
    return result;
}

/* Function G.2: Bottom Oil Temperature
 
 ΘBO = ΘAO - ΔΘTOverB / 2

 Where:
 ΘAO is the average fluid temperature in tank and radiator, °C
 ΔΘTOverB is the ratio of temperature rise of fluid at top of radiator over bottom fluid, °C
 
 Returns:
 ΘBO, which is the bottom fluid temperature, °C
 
 */
double Theta_BO(double theta_AO, double delta_theta_ToverB) {
    
    double result = theta_AO - delta_theta_ToverB / 2.0;
    
    return result;
}

/* Function G.3: Top Oil Temperature
 
 ΘTO = ΘAO + ΔΘTOverB / 2

 Where:
 ΘAO is the average fluid temperature in tank and radiator, °C
 ΔΘTOverB is the ratio of temperature rise of fluid at top of radiator over bottom fluid, °C
 
 Returns:
 ΘTO, which is the top fluid temperature, °C
 
 */
double Theta_TO(double theta_AO, double delta_theta_ToverB) {
    
    double result = theta_AO + delta_theta_ToverB / 2.0;
    
    return result;
}

/* Function G.4: Heat generated by the windings from time t1 to t2
 
 QGEN,W = K^2 (Pw x Kw + Pe / Kw) Δt
 
 Where:
 K is the ratio of load L to rated load, per unit
 Kw is the temperature correction for losses of winding
 Pe is the eddy loss of windings at rated load, W
 Pw is the winding I2R loss at rated load, W
 Δt is the time increment for calculation, min
 
 Returns:
 QGEN,W which is the heat generated by windings, W-min
 
 */
double Q_GEN_w(double K, double Kw, double Pe, double Pw, double delta_T) {
    
    double result = K * K * (Pw * Kw + Pe / Kw) * delta_T;
    
    return result;
}

/* Function G.5: Temperature Correction for Winding Losses
 
 Kw = (ΘW,1 + ΘK) / (ΘW,R + ΘK)
 
 Where:
 ΘK is the temperature factor for resistance correction, °C
 ΘW,1 is the average winding temperature at the prior time, °C
 ΘW,R is the average winding temperature at rated load tested, °C
 
 Returns:
 Kw, which is the temperature correction for losses of winding
 
 */
double Kw(double theta_W_R, double theta_W_1, double theta_K) {
    
    double result = (theta_W_1 + theta_K) / (theta_W_R + theta_K);
    
    return result;
}

/* Function G.6: The heat lost by the windings
   (NOTE: The standard shows a G.6A for ONAN, ONAF, and OFAF and G.6B for ODAF. We require the cooling type as an input to the routine and call the correct function accordingly).
 
 QLOST,W = ((ΘW,1 - ΘDAO,1) / (ΘW,1 - ΘDAO,R))^5/4 * (μW,R / μW,1)^1/4 * (Pw + Pe) * Δt
  
 Where:
 Pe is the eddy loss of windings at rated load, W
 Pw is the winding I2R loss at rated load, W
 ΘDAO,1 is the average temperature of fluid in cooling ducts at the prior time, °C
 ΘDAO,R is the average temperature of fluid in cooling ducts at rated load, °C
 ΘW,1 is the average winding temperature at the prior time, °C
 ΘW,R is the average winding temperature at rated load tested, °C
 Δt is the time increment for calculation, min
 μW,1 is the viscosity of fluid for average winding temperature rise at rated load at the prior time, cP
 μW,R is the viscosity of fluid for average winding temperature rise at rated load, cP
 
 Returns:
 QLOST,W which is the heat lost by winding, W-min
 
 */
double QLOST_W(PCH_CoolingTypes cType, double Pe, double Pw, double theta_DAO_1, double theta_DAO_R, double theta_W_1, double theta_W_R, double delta_T, double mu_W_1, double mu_W_R) {
    
    // if the cooling type is ODAF, we ignore the μ values
    double muFactor = 1.0;
    if (cType != ODAF) {
        
        muFactor = pow(mu_W_R / mu_W_1, 0.25);
    }
    
    double result = pow((theta_W_1 - theta_DAO_1) / (theta_W_R - theta_DAO_R), 1.25) * muFactor * delta_T;
    
    return result;
}

/* Function G.7: The mass and thermal capacitance of the windings
 
 MWCpW = τW (Pw + Pe) / (ΘW,R - ΘDAO,R)
 
 Where:
 Pe is the eddy loss of windings at rated load, W
 Pw is the winding I2R loss at rated load, W
 ΘDAO,R is the average temperature of fluid in cooling ducts at rated load, °C
 ΘW,R is the average winding temperature at rated load tested, °C
 τW is the winding time constant, min
 
 Returns:
 MWCpW, which is the winding mass times specific heat, W-min/°C
 
 */
double MCp_W(double Pw, double Pe, double tau_W, double theta_DAO_R, double theta_W_R) {
    
    double result = tau_W * (Pw + Pe) / (theta_W_R - theta_DAO_R);
    
    return result;
}

/* Function G.8: The average winding temperature at time t = t2
 
 ΘW,2 = (QGEN,W - QLOST,W + MWCpW * ΘW,1) / MWCpW
 
 Where:
 MWCpW is the winding mass times specific heat, W-min/°C
 QGEN,W is the heat generated by windings, W-min
 QLOST, W is the heat lost by winding, W-min
 ΘW,1 is the average winding temperature at the prior time, °C
 
 Returns:
 ΘW,2, which is the average winding temperature at the next instant of time, °C
 
 */
double Theta_W_2(double QGEN_W, double QLOST_W, double MCp_W, double theta_W_1) {
    
    double result = (QGEN_W - QLOST_W + MCp_W * theta_W_1) / MCp_W;
    
    return result;
}

/* Function G.9: Winding duct oil temperature rise over bottom oil
 
 ΔΘDO/BO = ΘTDO - ΘBO = ((QLOST,W / (Δt (Pw + Pe))^x)(ΘTDO,R - ΘBO,R)
 
 Where:
 Pe is the eddy loss of windings at rated load, W
 Pw is the winding I2R loss at rated load, W
 QLOST,W is the heat lost by winding, W-min
 x is the exponent for duct oil rise over bottom oil, and is 0.5 for ONAN, ONAF, and OFAF, 1.0 for ODAF
 ΘBO is the bottom fluid temperature, °C
 ΘBO,R is the bottom fluid temperature at rated load, °C
 ΘTDO is the fluid temperature at top of duct, °C
 ΘTDO,R is the fluid temperature at top of duct at rated load, °C
 Δt is the time increment for calculation, min
 
 Returns:
 ΔΘDO/BO is the temperature rise of fluid at top of duct over bottom fluid, °C
 
 */
double Delta_Theta_DOoverBO(double QLOST_W, double x, double delta_T, double Pw, double Pe, double theta_TDO_R, double theta_BO_R) {
    
    double result = pow(QLOST_W / (delta_T * (Pw + Pw)), x) * (theta_TDO_R - theta_BO_R);
    
    return result;
}

/* Function G.10: The oil temperature at the hot-spot elevation
 
 ΔΘWO/BO = HHS (ΘTDO − ΘBO)
 
 Where:
 HHS is the per unit of winding height to hot spot location
 ΘBO is the bottom fluid temperature, °C
 ΘTDO is the fluid temperature at top of duct, °C
 
 Returns:
 ΔΘWO/BO, which is the temperature rise of oil at winding hot-spot location over bottom oil, °C
 
 */
double Delta_Theta_WOoverBO(double HHS, double theta_BO, double theta_TDO) {
    
    double result = HHS * (theta_TDO - theta_BO);
    
    return result;
}

/* Function G.11: The temperature of oil adjacent to winding hot spot
   (NOTE: This routine combines G.11A and G.11B into a single function.)
 
 IF ΘTDO < ΘTO THEN ΘWO = ΘTO ELSE ΘWO = ΘBO + ΘWO/BO
 
 Where:
 ΘTDO is the fluid temperature at top of duct, °C
 ΘTO is the top fluid temperature in tank and radiator, °C
 ΘBO is the bottom fluid temperature, °C
 ΘWO/BO is the temperature of oil at winding hot-spot location over bottom oil, °C
 
 Returns:
 ΘWO, which is the temperature of oil adjacent to winding hot spot, °C
 
 */
double Theta_WO(double theta_TDO, double theta_TO, double theta_BO, double theta_WOoverBO) {
    
    double result = 0.0;
    
    if (theta_TDO < theta_TO) {
        
        result = theta_TO;
    }
    else {
        
        result = theta_BO + theta_WOoverBO;
    }
    
    return result;
}

/* Function G.12 & G.13: Correct the winding losses from average winding temperature to hot-spot temperature
   NOTE: The function expects a pointer to a two-element array of doubles. On exit, the first entry is the hot-spot I2R loss (G.12) and the second entry is the hot-spot eddy loss (G.13).
 
 PHS = ((ΘH,R + ΘK) / (ΘW,R + ΘK)) * PW (G.12)
 PEHS = EHS * PHS (G.13)
 
 Where:
 
 EHS, the eddy loss at winding hot spot location, per unit of I2R loss
 PW is the winding I2R loss at rated load, W
 ΘK is the temperature factor for resistance correction, °C
 ΘH,R is the winding hottest-spot temperature at rated load, °C
 ΘW,R is the average winding temperature at rated load tested, °C
 
 Returns (in array 'totalLoss'):
 Element 0: PHS, the Winding I2R loss at rated load and rated hot spot temperature, W
 Element 1: PEHS, the eddy loss at rated load and rated winding hot-spot temperature, W
 
 */
void P_TOTAL_HS(double Pw, double theta_H_R, double theta_W_R, double theta_K, double EHS, double *totalLoss) {
    
    if (totalLoss == NULL) {
        
        return;
    }
    
    double phs = Pw * (theta_H_R + theta_K) / (theta_W_R + theta_K);
    double pehs = EHS * phs;
    
    totalLoss[0] = phs;
    totalLoss[1] = pehs;
}

/* Function G.14: Heat generated at the hot-spot temperature.
 
 QGEN,HS = K^2 * (PHS * KHS + PEHS / KHS) * Δt
 
 Where:
 K is the ratio of load L to rated load, per unit
 KHS is the temperature correction for losses at hot spot location
 PEHS is the eddy loss at rated load and rated winding hot-spot temperature, W
 PHS is the winding I2R loss at rated load and rated hot spot temperature, W
 Δt is the time increment for calculation, min
 
 Returns:
 QGEN,HS, which is the heat generated at hot spot temperature, W-min
 
 */
double Q_GEN_HS(double K, double KHS, double PHS, double PEHS, double delta_T) {
    
    double result = K * K * (PHS * KHS + PEHS / KHS) * delta_T;
    
    return result;
}

/* Function G.15: Temperature correction for losses at hot-spot location
 
 KHS = (ΘH,1 + ΘK) / ((ΘH,R + ΘK)
 
 Where:
 ΘK is the temperature factor for resistance correction, °C
 ΘH,1 is the winding hottest-spot temperature at rated load at the prior time, °C
 ΘH,R is the winding hottest-spot temperature at rated load, °C
 
 Returns:
 KHS, which is the temperature correction for losses at hot spot location
 
 */
double KHS(double theta_H_1, double theta_H_R, double theta_K) {
    
    double result = (theta_H_1 + theta_K) / (theta_H_R + theta_K);
    
    return result;
}

/* Function G.16: The heat lost at the hot-spot location
 (NOTE: The standard shows a G.16A for ONAN, ONAF, and OFAF and G.16B for ODAF. We require the cooling type as an input to the routine and call the correct function accordingly).
 
 QLOST,HS = ((ΘH,1 - ΘWO) / (ΘH,R - ΘWO,R))^5/4 * (μHS,R / μHS,1)^1/4 * (PHS + PEHS) * Δt
 
 Where:
 PEHS is the eddy loss at rated load and rated winding hot-spot temperature, W
 PHS is the winding I2R loss at rated load and rated hot spot temperature, W
 ΘH,1 is the winding hottest-spot temperature at the prior time, °C
 ΘH,R is the winding hottest-spot temperature at rated load °C
 ΘWO is the temperature of oil adjacent to winding hot spot, °C
 ΘWO,R is the temperature of oil adjacent to winding hot spot at rated load, °C
 μHS,1 is the viscosity of fluid for hot-spot calculation at the prior time (ignored for ODAF), cP
 μHS,R is the viscosity of fluid for hot-spot calculation at rated load (ignored for ODAF), cP
 Δt is the time increment for calculation, min
 
 Returns:
 QLOST,HS is the heat lost for hot-spot calculation, W-min
 
 */
double QLOST_HS(PCH_CoolingTypes cType, double PEHS, double PHS, double theta_H_1, double theta_H_R, double theta_WO, double theta_WO_R, double delta_T, double mu_HS_1, double mu_HS_R) {
    
    // functionality is identical to G.6, so just call that
    return QLOST_W(cType, PEHS, PHS, theta_WO, theta_WO_R,  theta_H_1, theta_H_R, delta_T, mu_HS_1, mu_HS_R);
}

/* Function G.17: The winding hotspot temperature at time t2 (NOTE: This routine is functionally equivalent to G.8 so the underlying routine just calls that.)
 
 ΘH,2 = (QGEN,HS- QLOST,HS + MWCpW * ΘH,1) / MWCpW
 
 Where:
 MWCpW is the winding mass times specific heat, W-min/°C
 QGEN, HS is the heat generated at hot spot temperature, W-min
 QLOST, HS is the heat lost for hot-spot calculation, W-min
 ΘH,1 is the winding hottest-spot temperature at the prior time, °C
 
 Returns:
 ΘH,2, which is the winding hottest-spot temperature at the next instant of time, °C
 
 double Theta_W_2(double QGEN_W, double QLOST_W, double MCp_W, double theta_W_1)
 */
double Theta_H_2(double QGEN_HS, double QLOST_HS, double MCp_W, double theta_H_1) {
    
    return Theta_W_2(QGEN_HS, QLOST_HS, MCp_W, theta_H_1);
}

/* Function G.18: Heat generated by the core (NOTE: The standard creates a distinction between the heat generated by the core under normal conditions and when it is overexcited. We only create a single function here, and it s the calling routine's responsibility to pass the correct core loss to this routine.)
 
 QC = PC * Δt
 
 Where:
 PC is the core loss (no-load or overexcitation), W
 Δt is the time increment for calculation, min
 
 Returns:
 QC, which is the heat generated by core, W-min
 
 */
double QC(double PC, double delta_T) {
    
    double result = PC * delta_T;
    
    return result;
}

/* Function G.19: Heat generated by the stray loss
 
 QS = (K^2 * PS / KW) * Δt
 Where:
 K is the ratio of load L to rated load, per unit
 KW is the temperature correction for losses of winding
 PS is the stray losses at rated load, W
 Δt is the time increment for calculation, min
 
 Returns:
 QS, which is the heat generated by stray losses, W-min
 
 */
double QS(double K, double KW, double PS, double delta_T) {
    
    double result = delta_T * K * K * PS / KW;
    
    return result;
}

/* Function G.20 Total loss
 
 PT = PW + PE + PS + PC
 
 Where:
 PC is the core (no-load) loss, W
 PE is the eddy loss of windings at rated load, W
 PS is the stray losses at rated load, W
 PW is the winding I2R loss at rated load, W
 
 Returns:
 PT, which is the total losses at rated load, W
 
 */
double PT(double PW, double PE, double PS, double PC) {
    
    double result = PW + PE + PS + PC;
    
    return result;
}

/* Function G.21 Heat lost by the oil
 
 QLOST,O = ((ΘAO,1 - ΘA,1) / (ΘAO,R - ΘA,R))^1/y * PT * Δt
 
 Where:
 PT is the total losses at rated load, W
 ΘA,1 is the ambient temperature at the prior time, °C
 ΘA,R is the rated ambient at kVA base for load cycle, °C
 ΘAO,1 is the average fluid temperature in tank and radiator at the prior time, °C
 ΘAO,R is the average fluid temperature in tank and radiator at the rated load, °C
 Δt is the time increment for calculation, min
 y is the exponent of average fluid rise with heat loss, and is 0.8 for ONAN, 0.9 for ONAF and OFAF, and 1.0 for ODAF
 
 Returns:
 QLOST,O, which is the heat lost by fluid to ambient, W-min
 
 */
double QLOST_O(double theta_AO_1, double theta_A_1, double theta_AO_R, double theta_A_R, double y, double PT, double delta_T) {
    
    double result = pow((theta_AO_1 - theta_A_1) / (theta_AO_R - theta_A_R), 1.0 / y) * PT * delta_T;
    
    return result;
}

/* Function G.22 Mass of windings (transformer manufacturer would already have this data - ie: it would not need to be calculated)
 
 MW = MWCpW / CpW
 
 Where:
 CpW is the specific heat of winding material, W-min/lb °C
 MWCpW is the winding mass times specific heat, W-min/°C
 
 Returns:
 MW, which is the mass of windings, lb
 
 */
double MW(double MCpW, double CpW) {
    
    return MCpW / CpW;
}

/* Function G.23 Mass of core (transformer manufacturer would already have this data - ie: it would not need to be calculated)
 
 MCORE = MCC − MW
 
 Where:
 MCC is the core and coil (untanking) weight, lb
 MW is the mass of windings, lb
 
 Returns:
 MCORE is the mass of core, lb
 
 */
double MCORE(double MCC, double MW) {
    
    return MCC - MW;
}

/* Function G.24: Total mass times specific heat of oil, tank, and core
 
 ΣMCp = MTANK * CPTANK + MCORE * CPCORE + MOIL * CPOIL
 
 Where:
 CPCORE is the specific heat of the core, W-min/lb °C
 CPOIL is the specific heat of fluid, W-min/lb °C
 CPTANK is the specific heat of the tank, W-min/lb °C
 MCORE is the mass of core, lb
 MOIL is the mass of fluid, lb
 MTANK is the mass of tank, lb
 
 Returns:
 ΣMCp, which is the total mass times specific heat of oil, tank, and core, W-min/°C
 
 */
double SumMCp(double MTANK, double CPTANK, double MCORE, double CPCORE, double MOIL, double CPOIL) {
    
    double result = MTANK * CPTANK + MCORE * CPCORE + MOIL * CPOIL;
    
    return result;
}

/* Function G.25 Average oil temperature at time t2
 
 ΘAO,2 = (QLOST,W + QS + QC - QLOST,O + ΘAO,1 * ΣMCp) / ΣMCp
 
 Where:
 QLOST,O is the heat lost by fluid to ambient, W-min
 QLOST,W is the heat lost by winding, W-min
 QC is the heat generated by core, W-min
 QS is the heat generated by stray losses, W-min
 ΣMCp is the total mass times specific heat of fluid, tank, and core, W-min/°C
 ΘAO,1 is the average fluid temperature in tank and radiator at the prior time, °C
 
 Returns:
 ΘAO,2, which is the average fluid temperature in tank and radiator at the next instant of time, °C
 */

double Theta_AO_2(double QLOST_W, double QS, double QC, double QLOST_O, double theta_AO_1, double SumMCp) {
    
    double result = (QLOST_W + QS + QC - QLOST_O + theta_AO_1 * SumMCp) / SumMCp;
    
    return result;
}

/* Function G.26 Temperature rise of top-oil (radiator) over bottom-oil
 
 ΔΘT/B = (QLOST,O / (PT * Δt))^z * (ΘTO,R - ΘBO,R)
 
 Where:
 z is the exponent for top to bottom fluid temperature difference and is 0.5 for ONAN and ONAF; 1.0
 for OFAF and ODAF
 PT is the total losses at rated load, W
 QLOST,O is the heat lost by fluid to ambient, W-min
 ΘBO,R is the bottom fluid temperature at rated load, °C
 ΘTO,R is the top fluid temperature in tank and radiator at rated load, °C
 Δt is the time increment for calculation, min
 
 Returns:
 ΔΘT/B, which is the temperature rise of oil at top of radiator over bottom fluid, °C
 
 */
double Delta_Theta_ToverB(double QLOST_O, double PT, double delta_T, double z, double theta_TO_R, double theta_BO_R) {
    
    double result = pow(QLOST_O / (PT * delta_T), z) * (theta_TO_R - theta_BO_R);
    
    return result;
}
