function [FC,Exhaust] = oxy_fuelcell(options,Cathode)
F = 96485.33; %Faraday's Constant in Coulombs/mol
Ru = 8.314; %Universal gas constant, J/mol.K  
T = options.T_fc;
P = options.P_fc;
[n1,n2] = size(T);
W = 9; %Width of active cell area in cm
L = 9; %Length of active cell area in cm
n = 10; %Number of nodes at which the voltage change is calculated
FC.cell_area = W*L;
FC.i_total = 4000.*Cathode.O2.*F; %Total current produced at 100% O2 utilization
FC.i_den = FC.i_total./(options.SOFC_area*10000); %A/cm^2

FC.Cells = options.SOFC_area.*10000/FC.cell_area; % Number of cells based on total active surface area of 81 cm^2 per cell
FC.i_Cell = FC.cell_area*FC.i_den;%FC.i_total./FC.Cells; %Total amount of current per cell
dH = 0*T;
for k = 1:1:n2
%     dS(:,k) = refproparray('s','T',T(:,k),'P',P(:,k),'WATER')*18.01528 - refpropm('s','T',T(:,k),'P',P(:,k),'Hydrogen')*2.016 - .5*refpropm('s','T',T(:,k),'P',P(:,k),'Oxygen')*32;
    dH(:,k) = refproparray('h','T',T(:,k),'P',P(:,k),'WATER')*18.01528 - refproparray('h','T',T(:,k),'P',P(:,k),'Hydrogen')*2.016 - .5*refproparray('h','T',T(:,k),'P',P(:,k),'Oxygen')*32 - 45839000 - 241826400;%J/kmol
end
% E0 = -(dH-T.*dS)/(2000*F)%Reference Voltage

FC.G = -198141 + (T-900)*(-192652+198141)/(1000-900);
FC.G(T>1000) = -192652 + (T(T>1000)-1000)*(-187100+192652)/(1100-1000);
E0 = -FC.G/(2*F);

i = (ones(n1,n2,n)).*(FC.i_Cell./FC.cell_area); %Initial current density distribution per cell
J_int = zeros(n1,n2,n); %Initializing the matrix for Current distribution
FC.hrxnmol = -dH/1000; %H2 + 0.5*O2 -->  H2O, Heat Released in kJ/kmol

FC.H2_used = 2*Cathode.O2; %Flow of H2 Needed to React 100% O2 Flow kmol/s
FC.H2_supply = FC.H2_used./options.spu;
FC.H2O_supply = FC.H2_supply.*options.steamratio./(1-options.steamratio);
FC.n_in = FC.H2_supply + FC.H2O_supply;  


error_V = 1;
V = zeros(n1,n2);
asr = zeros(n1,n2,n);
for j = 1:1:n
    asr(:,:,j) = options.asr;
end
X_H2 = zeros(n1,n2,n);   
X_H2O = zeros(n1,n2,n);
E = zeros(n1,n2,n);
while max(max(abs(error_V)))>1e-4
    for k=1:1:n
        J_int(:,:,k) = sum(i(:,:,1:k),3).*(FC.cell_area/n); %integral of current density as a function of length, total current thus far
        X_H2(:,:,k) = (FC.H2_supply - J_int(:,:,k)./(2000*F./FC.Cells))./(FC.n_in); %Concentration of H2 as a function of position and steam concentration
        X_H2O(:,:,k) = 1-X_H2(:,:,k); %Concentration of H20 product as H2 is consumed 
        E(:,:,k) = E0 + Ru*T./(2*F).*log(X_H2(:,:,k)./(X_H2O(:,:,k).*(P/100).^0.5)); %Nernst Potential as a function of product and reactant concentrations
    end
    error = 1;
    if error_V == 1
        V = sum(E-i.*asr,3)/n+.05;
        Vold = V;
    end
    while any(any(abs(error)>(FC.i_Cell*1e-4))) %|| count < 2
        i = max(0,E-V.*ones(1,1,n))./asr; %new current distribution
        error = (sum(i,3).*FC.cell_area/n) - FC.i_Cell; %error in total current
        V = V + 1*(error./FC.cell_area.*options.asr); %New average voltage 
    end  
    error_V = Vold - V;
    Vold = V;
end
FC.V = V;
Anode.T = options.T_fc - .5*options.dT_fc;
Anode.P = options.P_fc;
Anode.H2 = FC.H2_supply;
Anode.H2O = FC.H2O_supply; 
Exhaust.T = Anode.T + .5*options.dT_fc;
Exhaust.P = Anode.P;
Exhaust.H2 = Anode.H2 - FC.H2_used;
Exhaust.H2O = Anode.H2O + FC.H2_used; %Water/Steam Produced by Reaction, mol/s
FC.Power = FC.V.*FC.i_total./1000; %Electric Power produced by FC, kW
FC.Qgen =  FC.hrxnmol.*FC.i_total./(2000.*F) - FC.V.*FC.i_total./1000; %Heat generated by fuel cell, kW 
FC.Qremove = FC.Qgen - (property(Exhaust,'h','kJ')-property(Anode,'h','kJ')-property(Cathode,'h','kJ')); %heat removed by some means to maintain temperature in kW
FC.O2 = Cathode.O2;
FC.pressure = P;
end