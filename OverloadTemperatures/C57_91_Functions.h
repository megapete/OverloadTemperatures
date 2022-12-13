//
//  C57_91_Functions.h
//  OverloadTemperatures
//
//  Created by Peter Huber on 2022-12-12.
//

#ifndef C57_91_Functions_h
#define C57_91_Functions_h

#include <stdio.h>

// The different cooling types
typedef enum {
    
    ONAN,
    ONAF,
    OFAF,
    ODAF
    
} PCH_CoolingTypes;

// The different winding conductor types
typedef enum {
    
    CU,
    AL
    
} PCH_ConductorTypes;

// The different fluids
typedef enum {
    
    MINERAL_OIL,
    SILICON_OIL
    
} PCH_FluidTypes;

// Functions
// G.1
double Theta_H(double theta_A, double delta_theta_BO, double delta_theta_WOBO, double delta_theta_HWO);
// G.2
double Theta_BO(double theta_AO, double delta_theta_ToverB);
// G.3
double Theta_TO(double theta_AO, double delta_theta_ToverB);
// G.4
double Q_GEN_w(double K, double Kw, double Pe, double Pw, double delta_T);
// G.5
double Kw(double theta_Wr, double theta_W1, double theta_K);
// G.6
double QLOST_W(PCH_CoolingTypes cType, double Pe, double Pw, double theta_DAO1, double theta_DAOR, double theta_W1, double theta_Wr, double delta_T, double mu_W1, double mu_Wr);
// G.7
double MCp_W(double Pw, double Pe, double tau_W, double theta_DAOR, double theta_Wr);
// G.8
double Theta_W2(double QGEN_W, double QLOST_W, double MCp_W, double theta_W1);
// G.9
double Delta_Theta_DOoverBO(double QLOST_W, double x, double delta_T, double Pw, double Pe, double theta_TDOR, double theta_BOR);

#endif /* C57_91_Functions_h */
