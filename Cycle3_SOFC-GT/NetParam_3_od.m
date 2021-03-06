function [Weight,paramod] = NetParam_3_od(options,FCArray,intake,HL,E4)
Ein = (FCArray.H2in + HL.H2used).*FCArray.hrxnmol; %Lower heating value of fuel intake, kJ/kmol
Eout = FCArray.Power + intake.C1_work + HL.T1_work;
paramod.FTE = Eout./Ein;
paramod.FC_eff = FCArray.Power./(FCArray.H2used.*FCArray.hrxnmol);
paramod.FCPower = FCArray.Power;
paramod.NetPower = Eout;
paramod.Cells = FCArray.Cells; 
paramod.O2used = FCArray.O2used;
paramod.O2util = FCArray.O2util;
paramod.preheat_air = intake.heat_added; 
paramod.FCVoltage = FCArray.FCVoltage;
paramod.Qgen = FCArray.Qgen; 
paramod.Qoutanode = HL.Qoutanode;
paramod.Qoutcathode = HL.Qoutcathode;
paramod.H2_used = FCArray.H2in + HL.H2used; 
[Weight] = weight_3(options,paramod,FCArray,intake,HL,E4);
paramod.weight = Weight.Total;
paramod.weightComp = Weight.comp;
paramod.weightTurb = Weight.turb;
paramod.weightFC = Weight.sofc; 
paramod.weightHX = Weight.hx; 
paramod.iden = FCArray.iDenArray;
paramod.C1_work = intake.C1_work;
paramod.T1_work = HL.T1_work; 
paramod.hrxnmol = FCArray.hrxnmol;
paramod.Qbalance = HL.Qexcess;
paramod.CoolingLoad = HL.CoolingLoad; 
paramod.P_den = Eout./paramod.weight;
end
