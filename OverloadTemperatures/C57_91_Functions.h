//
//  C57_91_Functions.h
//  OverloadTemperatures
//
//  Created by Peter Huber (Huberis Technologies Inc.) on 2022-12-12.
//

// This is the basic implementation of the equations given in C57.91-2011. References to particular equations in the standard are indicated as "G.xx" where 'xx' is the equation number.

// NOTE 1: This file (and its implementation file) conforms to GNU11, which is basically C11 with GNU extensions. I do not (to my knowledge) use GNU extensions, so it should also be compatible with C11. This may change if Visual Studio compatibilty becomes an issue.

// NOTE 2: The function and variable names are really ugly but are designed to closely match the names used in the standard (for easier reference). Comments are included in this header file that explain the parameters & functions using the same descriptions that are found in the 2011 revision of the standard (literally: they have been copied directly from the standard and pasted directly into the comments). Higher-level access to the functions should probably use more desctiptive function and variable names.

// NOTE 3: Error-handling is basically non-existant at this level (most of the implementations are straight-forward enough that errors should be immediately obvious). That said, error-checking should be done by higher-level access routines before calling anything in this library.

#ifndef C57_91_Functions_h
#define C57_91_Functions_h

#include <stdio.h>
#include <stdbool.h>

// Tell the C++ compiler that this is C code
#ifdef __cplusplus
extern "C" {
#endif

// do some conditional compilation
#ifdef __APPLE__
#include <CoreFoundation/CFAvailability.h>
#endif

// enums are ugly in Swift if we don't use some fancy macros, but for non-Apple systems we want to use simple emums
#ifdef CF_ENUM

// The different cooling types
typedef CF_ENUM(int, C57_91_CoolingType) {
    
    ONAN = 0,
    ONAF = 1,
    OFAF = 2,
    ODAF = 3
};

// The different winding conductor types
typedef CF_ENUM(int, C57_91_ConductorType) {
    
    CU = 0,
    AL = 1
};

// The different fluids
typedef CF_ENUM(int, C57_91_FluidType) {
    
    MINERAL_OIL = 0,
    SILICON_OIL = 1,
    HTHC = 2,
    C57_91_FLUIDTYPE_LAST_ENTRY // if this list is ever expanded, this entry must always be the last element of the enum
};

#else // non-Apple implementation

// _Nonnull and _Nullable are required for Swift but nothing else, so we define dummy macros that do nothing in C/C++ (ie: Windows)
#ifndef _Nonnull
#define _Nonnull
#endif

#ifndef _Nullable
#define _Nullable
#endif

// The different cooling types
typedef enum {
    
    ONAN = 0,
    ONAF,
    OFAF,
    ODAF
    
} C57_91_CoolingType;

// The different winding conductor types
typedef enum {
    
    CU = 0,
    AL
    
} C57_91_ConductorType;

// The different fluids
typedef enum {
    
    MINERAL_OIL = 0,
    SILICON_OIL,
    HTHC,
    C57_91_FLUIDTYPE_LAST_ENTRY // if this list is ever expanded, this entry must always be the last element of the enum
    
} C57_91_FluidType;

#endif

// Constants for the different conductors
typedef struct {
    
    double Tk; // Temperature base
    double Cp; // Specific Heat
    
} C57_91_ConductorCharacteristics;

// Constants used to calculate fluid viscosity at different temperatures (Equation G.28)
typedef struct {
    
    double Cp; // Specific Heat
    double D; // constant
    double G; // constant
    
} C57_91_FluidCharacteristics;

// Defines for the specific heat of steel materials used in transformers (from C57.91-2011 Table G.2)
#define SPECIFIC_HEAT_STEEL         3.51
#define SPECIFIC_HEAT_CORESTEEL     SPECIFIC_HEAT_STEEL

// Fixed conductor characteristics. To access a particular value of the array, use the C57_91_ConductorType as the index.
extern const C57_91_ConductorCharacteristics C57_91_StandardConductors[2];

// Fixed fluid characteristics (from table G.2). To access a particular value of the array, use the C57_91_FluidType as the index.
extern const C57_91_FluidCharacteristics C57_91_StandardFluids[C57_91_FLUIDTYPE_LAST_ENTRY - MINERAL_OIL];

// Typical exponent values (from table G.3). Use C57_91_CoolingType as the index into each array.
extern const double C57_91_X[4];
extern const double C57_91_Y[4];
extern const double C57_91_Z[4];

// 'Standard' exponents to be used when test data is not available
// extern const

// Functions
/// G.1: Hottest-spot temperature
/// - Parameter theta_A: the average ambient temperature during the load cycle to be studied, °C
/// - Parameter delta_theta_BO: the bottom fluid rise over ambient, °C
/// - Parameter delta_theta_WOoverBO: the temperature rise of oil at hotspot location over bottom oil, °C
/// - Parameter delta_theta_HoverWO: the hotspot temperature rise over oil next to hotspot location, °C
/// - Returns: The winding hottest spot temperature, °C
double Theta_H(double theta_A, double delta_theta_BO, double delta_theta_WOoverBO, double delta_theta_HoverWO);

/// G.2: Bottom Oil Temperature
/// - Parameter theta_AO: the average fluid temperature in tank and radiator, °C
/// - Parameter delta_theta_ToverB: the temperature rise of fluid at top of radiator over bottom fluid, °C
/// - Returns: The bottom fluid temperature, °C
double Theta_BO(double theta_AO, double delta_theta_ToverB);

/// G.3: Top Oil Temperature
/// - Parameter theta_AO: the average fluid temperature in tank and radiator, °C
/// - Parameter delta_theta_ToverB: the temperature rise of fluid at top of radiator over bottom fluid, °C
/// - Returns: The top fluid temperature, °C
double Theta_TO(double theta_AO, double delta_theta_ToverB);

/// G.4: Heat generated by the windings from time t1 to t2
/// - Parameter K: the ratio of load L to rated load, per unit
/// - Parameter Kw: the temperature correction for losses of winding
/// - Parameter Pe: the eddy loss of windings at rated load, W
/// - Parameter Pw: the winding I2R loss at rated load, W
/// - Parameter delta_T: the time increment for calculation, min
/// - Returns: The heat generated by windings, W-min
double Q_GEN_W(double K, double Kw, double Pe, double Pw, double delta_T);

/// G.5: Temperature Correction for Winding Losses
/// - Parameter theta_W_R: the average winding temperature at rated load tested, °C
/// - Parameter theta_W_1: the average winding temperature at the prior time, °C
/// - Parameter theta_K: the temperature factor for resistance correction, °C
/// - Returns: The temperature correction for losses of winding
double Kw(double theta_W_R, double theta_W_1, double theta_K);

/// G.6: The heat lost by the windings
/// - Note: The standard defines a G.6A for ONAN, ONAF, and OFAF and G.6B for ODAF. This function requires the cooling type as an input to the routine and does the correct calculation accordingly.
/// - Parameter cType: the cooling type, C57_91_CoolingType
/// - Parameter Pe: the eddy loss of windings at rated load, W
/// - Parameter Pw: the winding I2R loss at rated load, W
/// - Parameter theta_DAO_1: the average temperature of fluid in cooling ducts at the prior time, °C
/// - Parameter theta_DAO_R: the average temperature of fluid in cooling ducts at rated load, °C
/// - Parameter theta_W_1: the average winding temperature at the prior time, °C
/// - Parameter theta_W_R: the average winding temperature at rated load tested, °C
/// - Parameter delta_T: the time increment for calculation, min
/// - Parameter mu_W_1: the viscosity of fluid for average winding temperature rise at rated load at the prior time, cP (ignored for ODAF cooling)
/// - Parameter mu_W_R: the viscosity of fluid for average winding temperature rise at rated load, cP (ignored for ODAF cooling)
/// - Returns: The heat lost by winding, W-min
double QLOST_W(C57_91_CoolingType cType, double Pe, double Pw, double theta_DAO_1, double theta_DAO_R, double theta_W_1, double theta_W_R, double delta_T, double mu_W_1, double mu_W_R);

/// G.7: The mass and thermal capacitance of the windings
/// - Parameter Pe: the eddy loss of windings at rated load, W
/// - Parameter Pw: the winding I2R loss at rated load, W
/// - Parameter tau_W: the winding time constant, min
/// - Parameter theta_DAO_R: the average temperature of fluid in cooling ducts at rated load, °C
/// - Parameter theta_W_R: the average winding temperature at rated load tested, °C
/// - Returns: The winding mass times specific heat, W-min/°C
double MCp_W(double Pw, double Pe, double tau_W, double theta_DAO_R, double theta_W_R);

/// G.8: The average winding temperature at time t = t2
/// - Parameter QGEN_W: the heat generated by windings, W-min
/// - Parameter QLOST_W: the heat lost by winding, W-min
/// - Parameter MCp_W: the winding mass times specific heat, W-min/°C
/// - Parameter theta_W_1: the average winding temperature at the prior time, °C
/// - Returns: The average winding temperature at the next instant of time, °C
double Theta_W_2(double QGEN_W, double QLOST_W, double MCp_W, double theta_W_1);

/// G.9: The temperature rise of fluid at top of duct over bottom fluid
/// - Parameter QLOST_W: the heat lost by winding, W-min
/// - Parameter x: the exponent for duct oil rise over bottom oil
/// - Parameter delta_T: the time increment for calculation, min
/// - Parameter Pw: the winding I2R loss at rated load, W
/// - Parameter Pe: the eddy loss of windings at rated load, W
/// - Parameter theta_TDO_R: the fluid temperature at top of duct at rated load, °C
/// - Parameter theta_BO_R: the bottom fluid temperature at rated load, °C
/// - Returns: The temperature rise of fluid at top of duct over bottom fluid, °C
double Delta_Theta_DOoverBO(double QLOST_W, double x, double delta_T, double Pw, double Pe, double theta_TDO_R, double theta_BO_R);

/// G.10: The temperature rise of oil at winding hot-spot location over bottom oil
/// - Parameter HHS: the per unit of winding height to hot spot location
/// - Parameter theta_BO: the bottom fluid temperature, °C
/// - Parameter theta_TDO: the fluid temperature at top of duct, °C
/// - Returns: The temperature rise of oil at winding hot-spot location over bottom oil, °C
double Delta_Theta_WOoverBO(double HHS, double theta_BO, double theta_TDO);

/// G.11: The temperature of oil adjacent to winding hot spot
/// - NOTE: This routine combines G.11A and G.11B into a single function.
/// - Parameter theta_TDO: the fluid temperature at top of duct, °C
/// - Parameter theta_TO: the top fluid temperature in tank and radiator, °C
/// - Parameter theta_BO: the bottom fluid temperature, °C
/// - Parameter theta_WOoverBO: the temperature of oil at winding hot-spot location over bottom oil, °C
/// - Returns: The temperature of oil adjacent to winding hot spot, °C
double Theta_WO(double theta_TDO, double theta_TO, double theta_BO, double theta_WOoverBO);

/// G.12 & G.13: Correct the winding losses from average winding temperature to hot-spot temperature.
/// - NOTE: The function expects a two-element array of doubles (totalLoss). Whatever values the array holds on entry will be overwritten. On exit, the first entry is the hot-spot I2R loss (G.12) and the second entry is the hot-spot eddy loss (G.13).
/// - Parameter Pw: the winding I2R loss at rated load, W
/// - Parameter theta_H_R: the winding hottest-spot temperature at rated load, °C
/// - Parameter theta_W_R: the average winding temperature at rated load tested, °C
/// - Parameter theta_K: the temperature factor for resistance correction, °C
/// - Parameter EHS: the eddy loss at winding hot spot location, per unit of I2R loss
/// - Parameter totalLoss: A two-element array of double
/// - Returns: First element of totalLoss is the winding I2R loss at rated load and rated hot spot temperature, W; Second element is the eddy loss at rated load and rated winding hot-spot temperature, W
void P_TOTAL_HS(double Pw, double theta_H_R, double theta_W_R, double theta_K, double EHS, double *_Nonnull totalLoss);

/// G.14: Heat generated at the hot-spot temperature.
/// - Parameter K: the ratio of load L to rated load, per unit
/// - Parameter KHS: the temperature correction for losses at hot spot location
/// - Parameter PHS: the winding I2R loss at rated load and rated hot spot temperature, W
/// - Parameter PEHS: the eddy loss at rated load and rated winding hot-spot temperature, W
/// - Parameter delta_T: the time increment for calculation, min
/// - Returns: The heat generated at hot spot temperature, W-min
double Q_GEN_HS(double K, double KHS, double PHS, double PEHS, double delta_T);

/// G.15: Temperature correction for losses at hot-spot location
/// - Parameter theta_H_1: the winding hottest-spot temperature at the prior time, °C
/// - Parameter theta_H_R: the winding hottest-spot temperature at rated load, °C
/// - Parameter theta_K: the temperature factor for resistance correction, °C
/// - Returns: The temperature correction for losses at hot spot location
double KHS(double theta_H_1, double theta_H_R, double theta_K);

/// G.16: The heat lost at the hot-spot location
/// - NOTE: The standard defines a G.16A for ONAN, ONAF, and OFAF and G.16B for ODAF. We require the cooling type as an input to the routine and call the correct function accordingly. Also, functionally, this equation is identical to G.6, so this routine just calls QLOST_W.
/// - Parameter cType: the cooling type, C57_91_CoolingType
/// - Parameter PEHS: the eddy loss at rated load and rated winding hot-spot temperature, W
/// - Parameter PHS: the winding I2R loss at rated load and rated hot spot temperature, W
/// - Parameter theta_H_1: the winding hottest-spot temperature at the prior time, °C
/// - Parameter theta_H_R: the winding hottest-spot temperature at rated load °C
/// - Parameter theta_WO: the temperature of oil adjacent to winding hot spot, °C
/// - Parameter theta_WO_R: the temperature of oil adjacent to winding hot spot at rated load, °C
/// - Parameter delta_T: the time increment for calculation, min
/// - Parameter mu_HS_1: the viscosity of fluid for hot-spot calculation at the prior time, cP (ignored if cooling is ODAF)
/// - Parameter mu_HS_R: the viscosity of fluid for hot-spot calculation at rated load, cP (ignored if cooling is ODAF)
/// - Returns: The heat lost for hot-spot calculation, W-min
double QLOST_HS(C57_91_CoolingType cType, double PEHS, double PHS, double theta_H_1, double theta_H_R, double theta_WO, double theta_WO_R, double delta_T, double mu_HS_1, double mu_HS_R);

/// G.17: The winding hotspot temperature at time t2
/// - NOTE: This routine is functionally equivalent to G.8 so the underlying routine just calls that.
/// - Parameter QGEN_HS: the heat generated at hot spot temperature, W-min
/// - Parameter QLOST_HS: the heat lost for hot-spot calculation, W-min
/// - Parameter MCp_W: the winding mass times specific heat, W-min/°C
/// - Parameter theta_H_1: the winding hottest-spot temperature at the prior time, °C
/// - Returns: The winding hottest-spot temperature at the next instant of time, °C
double Theta_H_2(double QGEN_HS, double QLOST_HS, double MCp_W, double theta_H_1);

/// G.18: Heat generated by the core
/// - NOTE: The standard creates a distinction between the heat generated by the core under normal conditions and when it is overexcited. We only create a single function here, and it is the calling routine's responsibility to pass the correct core loss to this routine.
/// - Parameter PC: the core loss for which we want the heat generated, W
/// - Parameter delta_T: the time increment for calculation, min
/// - Returns: The heat generated by core, W-min
double QC(double PC, double delta_T);

/// G.19: Heat generated by the stray loss
/// - Parameter K: the ratio of load L to rated load, per unit
/// - Parameter KW: the temperature correction for losses of winding
/// - Parameter PS: the stray losses at rated load, W
/// - Parameter delta_T: the time increment for calculation, min
/// - Returns: The heat generated by stray losses, W-min
double QS(double K, double KW, double PS, double delta_T);

/// G.20 Total loss
/// - Parameter PW: the winding I2R loss at rated load, W
/// - Parameter PE: the eddy loss of windings at rated load, W
/// - Parameter PS: the stray losses at rated load, W
/// - Parameter PC: the core (no-load) loss, W
/// - Returns: The total losses at rated load, W
double PT(double PW, double PE, double PS, double PC);

/// G.21 Heat lost by the oil
/// - Parameter theta_AO_1: the average fluid temperature in tank and radiator at the prior time, °C
/// - Parameter theta_A_1: the ambient temperature at the prior time, °C
/// - Parameter theta_AO_R: the average fluid temperature in tank and radiator at the rated load, °C
/// - Parameter theta_A_R: the rated ambient at kVA base for load cycle, °C
/// - Parameter y: the exponent of average fluid rise with heat loss (also known as 'n' in most literature)
/// - Parameter PT: the total losses at rated load, W
/// - Parameter delta_T: the time increment for calculation, min
/// - Returns: The heat lost by fluid to ambient, W-min
double QLOST_O(double theta_AO_1, double theta_A_1, double theta_AO_R, double theta_A_R, double y, double PT, double delta_T);

/// G.22 Mass of windings
/// - Note: A transformer manufacturer would already have this data - ie: it would not need to be calculated this way
/// - Parameter MCpW: the winding mass times specific heat, W-min/°C
/// - Parameter CpW: the specific heat of winding material, W-min/lb °C
/// - Returns: The (estimated) mass of windings, lb
double MW(double MCpW, double CpW);

/// G.23 Mass of core
/// - Note: A transformer manufacturer would already have this data - ie: it would not need to be calculated this way
/// - Parameter MCC: the core and coil (untanking) weight, lb
/// - Parameter MW: the mass of windings, lb
/// - Returns: the mass of core, lb
double MCORE(double MCC, double MW);

/// G.24: Total mass times specific heat of oil, tank, and core
/// - Parameter MTANK: the mass of tank, lb
/// - Parameter CPTANK: the specific heat of the tank, W-min/lb °C
/// - Parameter MCORE: the mass of core, lb
/// - Parameter CPCORE: the specific heat of the core, W-min/lb °C
/// - Parameter MOIL: the mass of fluid, lb
/// - Parameter CPOIL: the specific heat of fluid, W-min/lb °C
/// - Returns: The total mass times specific heat of oil, tank, and core, W-min/°C
double SumMCp(double MTANK, double CPTANK, double MCORE, double CPCORE, double MOIL, double CPOIL);

/// G.25: Average oil temperature at time t2
/// - Parameter QLOST_W: the heat lost by winding, W-min
/// - Parameter QS: the heat generated by stray losses, W-min
/// - Parameter QC: the heat generated by core, W-min
/// - Parameter QLOST_O: the heat lost by fluid to ambient, W-min
/// - Parameter theta_AO_1: the average fluid temperature in tank and radiator at the prior time, °C
/// - Parameter SumMCp: the total mass times specific heat of fluid, tank, and core, W-min/°C
/// - Returns: The average fluid temperature in tank and radiator at the next instant of time, °C
double Theta_AO_2(double QLOST_W, double QS, double QC, double QLOST_O, double theta_AO_1, double SumMCp);

/// G.26 Temperature rise of top-oil (radiator) over bottom-oil
///  - Parameter QLOST_O: the heat lost by fluid to ambient, W-min
///  - Parameter PT: the total losses at rated load, W
///  - Parameter delta_T: the time increment for calculation, min
///  - Parameter z: the exponent for top to bottom fluid temperature difference
///  - Parameter theta_TO_R: the top fluid temperature in tank and radiator at rated load, °C
///  - Parameter theta_BO_R: the bottom fluid temperature at rated load, °C
///  - Returns: The temperature rise of oil at top of radiator over bottom fluid, °C
double Delta_Theta_ToverB(double QLOST_O, double PT, double delta_T, double z, double theta_TO_R, double theta_BO_R);

/// G.27 Stability requirement
/// - NOTE: This function checks that the time interval (Δt) is small enough so that the systems of equations are stable. There are 4 different inequalities defined by the standard. All of them are combined into this single function. If the 'useSimplified'  field is set (or cType is ODAF), G.27D (G.27C) is used with parameters τW and Δt and the remaining input parameters are ignored (the calling routine must still provide a viable tauW and pointer for the maxDeltaT parameter). The temperature and viscosity parameters are all passed as 2-element arrays where the first element is the average temperature and the second element is hot-spot) The 'maxDeltaT' parameter is set to the maximum value of Δt that will satisfy the criteria.
/// - Parameter useSimplified: if true, use the simplified criteria of equation G.27D to evaulate staibility (all other parameters are ignored except tauW and maxDeltaT, which must point to a valid memory location
/// - Parameter cType: the cooling type, C57_91_CoolingType
/// - Parameter tau_W: the winding time constant, min
/// - Parameter delta_T: the time increment for calculation, min
/// - Parameter maxDeltaT: A pointer to a double. Whatever value is there on entry will be overwritten by the rountine. On exit, the value pointed to will be the maximum value of delta_T that can be used and still have the equations be stable.
/// - Parameter wdgTemp_1: An array of two doubles (°C):  Element 0: the average winding temperature at the prior time; Element 1: the winding hottest-spot temperature at the prior time
/// - Parameter wdgTemp_R: An array of two doubles (°C):  Element 0: the average winding temperature at rated load (tested); Element 1: the winding hottest-spot temperature at rated load
/// - Parameter oilTemp_1: An array of two doubles (°C):  Element 0: the average temperature of fluid in cooling ducts at the prior time; Element 1: the temperature of oil adjacent to winding hot spot
/// - Parameter oilTemp_R: An array of two doubles (°C):  Element 0: the average temperature of fluid in cooling ducts at rated load; Element 1: the temperature of oil adjacent to winding hot spot at rated load
/// - Parameter viscosity_1: An array of two doubles (cP):  Element 0: tthe viscosity of fluid for average winding temperature at the prior time; Element 1: the viscosity of fluid for hot-spot calculation at the prior time
/// - Parameter viscosity_R: An array of two doubles (cP):  Element 0: tthe viscosity of fluid for average winding temperature  at rated load; Element 1: the viscosity of fluid for hot-spot calculation at rated load
/// - Returns: True if the systems of equations are stable, otherwise false. On exit, the maxDeltaT pointer will point to the maximum value of delta_T that can be used and still have the equations be stable.
bool TestStability(bool useSimplified, C57_91_CoolingType cType, double tau_W, double delta_T, double *_Nonnull maxDeltaT, double *_Nullable wdgTemp_1, double *_Nullable wdgTemp_R, double *_Nullable oilTemp_1, double *_Nullable oilTemp_R, double *_Nullable viscosity_1, double *_Nullable viscosity_R);

/// G.28 Fluid viscosity at different temperatures
/// - Parameter ftype: the fluid type, C57_91_FluidType
/// - Parameter theta: the temperature of oil to use for viscosity, °C
/// - Returns: the viscosity of oil, centipoises
double MU(C57_91_FluidType fType, double theta);

// Close the braces for extern "C"
#ifdef __cplusplus
}
#endif

#endif /* C57_91_Functions_h */
