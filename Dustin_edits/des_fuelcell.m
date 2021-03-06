function [FC,cath_out,anode_out,anode_in,cath_in] = des_fuelcell(options,comp_out)
%% determine operating condition (Voltage) that balances the excess fuel cell heat with the air pre-heating
F = 96485.33; %Faraday's Constant in Coulombs/mol
Ru = 8.314; %Universal gas constant, J/mol.K  
T = options.T_fc;
P = comp_out.P;
[E0,dG,dH] = std_potential(T);
[n1,n2] = size(T);
W = 9; %Width of active cell area in cm
L = 9; %Length of active cell area in cm
n = 10; %Number of nodes at which the voltage change is calculated

n_cells = options.SOFC_area.*10000/(W*L); % Number of cells based on total active surface area

cath_in = comp_out;
cath_in.T = options.T_fc - .5*options.dT_fc;
cath_out = cath_in;
cath_out.T = options.T_fc + .5*options.dT_fc;
Q_heat_pipe = max(0,enthalpy(cath_in) - enthalpy(comp_out));%Heat necessary to pre-heat air.

anode_in.T = options.T_fc - .5*options.dT_fc;
anode_in.P = P; 
anode_out.T = anode_in.T + options.dT_fc;
anode_out.P = anode_in.P;
ion.T = options.T_fc;
ion.P = P; 

%estimate voltage with bulk aproximation of composition and total current
error = 1;
V = .8;
while any(any(abs(error)>1e-3))
    i_total = (E0 + Ru*T./(2*F).*log(.65*.15/.35.*(P/100).^0.5) - V)./options.asr*1e4.*options.SOFC_area; %current estimate using average OCV
    while any(any(i_total < 0))
        V = V - 0.05;
        i_total = (E0 + Ru*T./(2*F).*log(.65*.15/.35.*(P/100).^0.5) - V)./options.asr*1e4.*options.SOFC_area; %updated average OCV to eliminate negative current
    end
    anode_in.H2 = i_total./(2000.*F)./options.spu;
    anode_in.H2O = anode_in.H2.*options.steamratio./(1-options.steamratio);
    anode_out.H2 = anode_in.H2 - i_total./(2000.*F);
    anode_out.H2O = anode_in.H2O + i_total./(2000.*F); %Water/Steam Produced by Reaction, mol/s
    ion.O2 = i_total./(4000.*F);
    cath_out.O2 = cath_in.O2 - ion.O2;
    Q_cath = enthalpy(cath_out) - enthalpy(cath_in) + enthalpy(ion);
    Q_anode = enthalpy(anode_out) - enthalpy(anode_in) - enthalpy(ion) - dH.*i_total./(2000.*F);
    error = (-dH.*i_total./(2000.*F) - V.*i_total./1000 - Q_anode - Q_cath - Q_heat_pipe)./(Q_cath+ Q_heat_pipe);
    error(isnan(error)) = 0;
    V = max(.25,min(1.1,V + .15*error.*max(0,(1.12-V))));
end

%initialize spatial matrices
i = (ones(n1,n2,n)).*(i_total./(1e4.*options.SOFC_area)); %Initial current density distribution per cell
J_int = zeros(n1,n2,n); %Cumulative current as function of length
asr = zeros(n1,n2,n);
for j = 1:1:n
    asr(:,:,j) = options.asr;
end
X_H2 = zeros(n1,n2,n);   
X_H2O = zeros(n1,n2,n);
X_O2 = zeros(n1,n2,n);
E = zeros(n1,n2,n);

%Solve for actual vlatage and total current using spatial discretization of composition and current
error_Q = 1;
while any(any(abs(error_Q)>1e-4))
    anode_in.H2 = i_total./(2000.*F)./options.spu;%Flow of H2 that reacts / utilization
    anode_in.H2O = anode_in.H2.*options.steamratio./(1-options.steamratio);
    n_in = anode_in.H2 + anode_in.H2O;  
    for k=1:1:n
        J_int(:,:,k) = sum(i(:,:,1:k),3).*(W*L/n); %integral of current density as a function of length, total current thus far
        X_H2(:,:,k) = (anode_in.H2 - J_int(:,:,k)./(2000*F./n_cells))./(n_in); %Concentration of H2 as a function of position and steam concentration
        X_H2O(:,:,k) = 1-X_H2(:,:,k); %Concentration of H20 product as H2 is consumed 
        X_O2(:,:,k) = (cath_in.O2 - J_int(:,:,k)./(4000*F./n_cells))./(net_flow(cath_in) - J_int(:,:,k)./(4000*F./n_cells));
        E(:,:,k) = E0 + Ru*T./(2*F).*log(X_H2(:,:,k).*X_O2(:,:,k)./(X_H2O(:,:,k).*(P/100).^0.5)); %Nernst Potential as a function of product and reactant concentrations
    end
    error = 1;
    while any(any(abs(error)>1e-4)) 
        i = max(0,E-V.*ones(1,1,n))./asr; %new current distribution
        error = (sum(i,3).*options.SOFC_area*1e4/n)./i_total -1; %error in total current
        error(isnan(error)) = 0;
        error(isinf(error)) = 0;
        V = min(1.4,max(.2,V + .25*error.*(i_total./options.SOFC_area/1e4.*options.asr))); %New average voltage 
    end  
    %% adjust H2 used based on cathode exit temperature
    anode_out.H2 = anode_in.H2 - i_total./(2000.*F);
    anode_out.H2O = anode_in.H2O + i_total./(2000.*F); %Water/Steam Produced by Reaction, mol/s
    ion.O2 = i_total./(4000.*F);
    cath_out.O2 = max(1e-3*cath_in.O2,cath_in.O2 - ion.O2);
    Q_cath = enthalpy(cath_out) - enthalpy(cath_in) + enthalpy(ion);
    Q_anode = enthalpy(anode_out) - enthalpy(anode_in) - enthalpy(ion) - dH.*i_total./(2000.*F);
    error_Q = (-dH.*i_total./(2000.*F) - V.*i_total./1000 - Q_anode - Q_cath - Q_heat_pipe)./(Q_cath+ Q_heat_pipe);
    i_total = i_total.*(1 -.5*error_Q);
end

FC.V = V;
FC.Power = V.*i_total./1000; %Electric Power produced by FC, kW
FC.O2 = ion.O2;
FC.O2_util = ion.O2./cath_in.O2;
FC.H2_supply = anode_in.H2;
FC.H2O_supply = anode_in.H2O;
FC.i_total = i_total;
FC.i_den = i_total./(options.SOFC_area*10000); %A/cm^2
FC.cell_area = W*L;% area in cm^2
FC.Cells = n_cells;
FC.i_Cell = FC.cell_area*FC.i_den;%FC.i_total./FC.Cells; %Total amount of current per cell
FC.pressure = P;
FC.hrxnmol = -dH; %H2 + 0.5*O2 -->  H2O, Heat Released in kJ/kmol
FC.Qgen = -dH.*i_total./(2000.*F) - V.*i_total./1000; %Heat generated by fuel cell, kW 
FC.Qremove = Q_heat_pipe;
FC.Q_pre_combustor = 0;
% FC.Qbalance = FC.Qremove;
end%Ends function des_fuelcell

function [E0,dG,dH] = std_potential(T)
F = 96485.33; %Faraday's Constant in Coulombs/mol
[n1,n2] = size(T);
reactant1.H2 = 1*ones(n1,n2); % 1 kmol of H2 for stoichiometric reaction
reactant1.T = T;
reactant2.O2 = 0.5*ones(n1,n2); % 0.5 kmol of O2 for stoichiometric reaction
reactant2.T = T; 
product.H2O = 1*ones(n1,n2); % 1 kmol of H2O as product
product.T = T;
dH = enthalpy(product) - enthalpy(reactant2) - enthalpy(reactant1); 
ds = entropy(product) - entropy(reactant2) - entropy(reactant1); 
dG = dH - T.*ds; 
E0 = -dG/(2*F);
end%Ends function std_potential