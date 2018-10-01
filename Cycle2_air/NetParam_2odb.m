function [Weight,paramod] = NetParam_2odb(options,FCArray,intake,HL,A1,Cells)
Ein = FCArray.H2used.*FCArray.hrxnmol; %Lower heating value of fuel intake, kJ/kmol
Eout = FCArray.Power + intake.C1_work + HL.blower_work + intake.T1_work;
paramod.FTE = Eout./Ein;
paramod.FC_eff = FCArray.Power./Ein;
paramod.FCPower = FCArray.Power;
paramod.NetPower = Eout;
paramod.Cells = FCArray.Cells; 
paramod.O2used = 0.21*FCArray.airin - FCArray.O2out;
paramod.O2util = FCArray.O2util;
paramod.preheat_air = intake.heat_added; 
paramod.FCVoltage = FCArray.FCVoltage;
paramod.Qgen = FCArray.Qgen;
paramod.Qremovefuel = HL.Qremove_fuel; 
paramod.Qoutanode = HL.Qoutanode;
paramod.Qoutcathode = HL.Qoutcathode;
paramod.H2_used = FCArray.H2used; 
[Weight] = weight_2odb(options,paramod,FCArray,Cells,HL,A1);
paramod.weight = Weight.Total;
paramod.weightComp = Weight.comp;
paramod.weightTurb = Weight.turb;
%paramod.weightCompArray(1,y) = Weight.comp(1,1);
%paramod.weightTurbArray(1,y) = Weight.turb(1,1);
paramod.weightFC = Weight.sofc; 
paramod.weightHX = Weight.hx; 
paramod.iden = FCArray.iDenArray;
paramod.C1_work = intake.C1_work;
paramod.T1_work = intake.T1_work; 
paramod.hrxnmol = FCArray.hrxnmol;
paramod.Qbalance = HL.Qexcess;
paramod.BlowerWork = HL.blower_work;
paramod.P_den = Eout./paramod.weight;
end

%    O2util =  i*0.035;
%         Cells = 100000 + 10000*j;
%         [FC,E1] = FuelCell_H2(T,ASR,A1,L,W,n,Cells,P,O2util,util,r);
%         FCArray.Power(i,j) = FC.Power;
%         FCArray.Qgen(i,j) = FC.Qgen;
%         FCArray.Efficiency(i,j) = FC.Efficiency;
%         FCArray.H2in(i,j) = FC.FuelFlow;
%         FCArray.H2out(i,j) = FC.Flow.H2;
%         FCArray.H2Oout(i,j) = FC.Flow.H2O;
%         FCArray.iDenArray(i,j) = FC.iDen;
%         FCArray.CellsArray(i,j) = Cells;
%         FCArray.FCVoltage(i,j) = FC.Voltage;
%         FCArray.O2out(i,j) = FC.O2out; 
%         FCArray.N2out(i,j) = FC.N2out; 
%         FCArray.H2used(i,j) = FC.H2used;
%         FCArray.E1H2(i,j) = E1.H2; 
%         FCArray.E1H2O(i,j) = E1.H2O; 
%         FCArray.H2Oin(i,j) = FC.H2Oin; 