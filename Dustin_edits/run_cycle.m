function param = run_cycle(options,mission,res_fuel)
%% calculate conditions for each design trade-off per kmol/s of inlet air
[m,n] = size(options.SOFC_area);
molar_flow = ones(m,n);
options.height = mission.alt(mission.design_point)*ones(m,n); %Altitude, meters
alt_tab = [0:200:7000,8000,9000,10000,12000,14000];%
atmosphere_density = [1.225,1.202,1.179,1.156,1.134,1.112,1.090,1.069,1.048,1.027,1.007,0.987,0.967,0.947,0.928,0.909,0.891,0.872,0.854,0.837,0.819,0.802,0.785,0.769,0.752,0.736,0.721,0.705,0.690,0.675,0.660,0.646,0.631,0.617,0.604,0.590,0.526,0.467,0.414,0.312,0.228]'; %Density, kg/m^3
air_den = interp1(alt_tab,atmosphere_density,options.height);

%% cycle simulation (output per kmol airflow
[A1,ss] = std_atmosphere(options.height,molar_flow);%Ambient conditions as a function of altitude
[A2,C1] = compressor(A1,options.PR_comp.*A1.P,options.C1_eff);
[OTM,C2,A3,A4,O1,O2,O3,O4,O5] = OxygenModule(options,A2);

%one-time adjustment of SOFC area per kmol air flow to ensure a feasible current density
i_den = 4000.*O5.O2.*96485.33./(options.SOFC_area*10000); %A/cm^2
i_den = max(.1,min(i_den,.7./options.asr));%Cant solve for ultra low or high current densities
options.SOFC_area = 4000.*O5.O2.*96485.33./i_den/1e4;
[FC,E1,F5] = oxy_fuelcell(options,O5);

[A5,T1] = expander(A4,A1.P,options.T1_eff);
[FL,B1,F2,F3,F4,E2,E3,E4,HX] = fuel_loop(options,E1,F5,A1);

%% Calculate nominal and mission power
mission.air_den = interp1(alt_tab,atmosphere_density,mission.alt);
[~,mission.ss] = std_atmosphere(mission.alt,1);%Ambient conditions as a function of altitude
for i = 1:1:length(mission.alt)
    velocity = mission.mach_num(i).*mission.ss(i);
    Thrust_Coefficient = mission.thrust(:,:,i)./(options.num_engines.*.5*mission.air_den(i).*velocity.^2*pi()*options.engine_radius.^2);
    Froude_efficiency = 2./(1+(1+Thrust_Coefficient).^.5);
    net_prop_eff = options.prop_eff.*Froude_efficiency;
    mission.power(:,:,i) = mission.thrust(:,:,i)*velocity./net_prop_eff/1000 + options.electric_demand;%shaft power in kW. 
end
P_nominal = mission.power(:,:,mission.design_point);%nominal power in kW

%% scale system to meet nominal power requirements
scale = options.safety_factor.*P_nominal./options.motor_eff./(FC.Power + C1.work + C2.work + T1.work + B1.work);
molar_flow = scale.*molar_flow;
vol_flow = molar_flow*28.84./air_den;%Volumetric flow at the design condition
options.SOFC_area = scale.*options.SOFC_area;
options.OTM_area = scale.*options.OTM_area;

%% Re-Run with scaled system parameters
[A1,~] = std_atmosphere(options.height,molar_flow);%Ambient conditions as a function of altitude
[A2,C1] = compressor(A1,options.PR_comp.*A1.P,options.C1_eff);
[OTM,C2,A3,A4,O1,O2,O3,O4,O5] = OxygenModule(options,A2);
[FC,E1,F5] = oxy_fuelcell(options,O5);
[A5,T1] = expander(A4,A1.P,options.T1_eff);
[FL,B1,F2,F3,F4,E2,E3,E4,HX] = fuel_loop(options,E1,F5,A1);
HX = otm_heat_exchangers(options,FC,OTM,HX,A1,O1,O2,O3,O4,O5);
HX.HP.mass = FC.Qremove.*options.heat_pipe_specific_mass; 

weight = system_weight(options,FC,{C1;T1;B1;C2},OTM,HX);
param = NetParam(options,FC,{C1;T1;B1;C2},OTM,FL);
param.states = {'A1',A1;'A2',A2;'A3',A3;'A4',A4;'A5',A5;'E1',E1;'E2',E2;'E3',E3;'E4',E4;'F2',F2;'F3',F3;'F4',F4;'F5',F5;'O1',O1;'O2',O2;'O3',O3;'O4',O4;'O5',O5;};

%% calculate off-design power output to meet mission profile for each condition by varying permeate pressure
weight.fuel = zeros(m,n);
battery_kJ = zeros(m,n);
fuel = zeros(m*n,1);
battery = zeros(m*n,1);
P_sys_mission = zeros(m*n,length(mission.alt));
eff_mission = zeros(m*n,length(mission.alt));
FCV_mission = zeros(m*n,length(mission.alt));
FCiden_mission = zeros(m*n,length(mission.alt));
param.power_mission = zeros(m,n,length(mission.alt));
param.efficiency_mission = zeros(m,n,length(mission.alt));
param.FCV_mission = zeros(m,n,length(mission.alt));
param.FCiden_mission = zeros(m,n,length(mission.alt));
param.TSFC_mission = zeros(m,n,length(mission.alt));
parallel = false;
if parallel
    parfor par_i = 1:1:m*n
        [fuel(par_i),battery(par_i),P_sys_mission(par_i,:),eff_mission(par_i,:),FCV_mission(par_i,:),FCiden_mission(par_i,:),TSFC_mission(par_i,:)] = flight_profile(options,mission,vol_flow,par_i,n);
    end
else
    for i = 1:1:m*n
        [fuel(i),battery(i),P_sys_mission(i,:),eff_mission(i,:),FCV_mission(i,:),FCiden_mission(i,:),TSFC_mission(i,:)] = flight_profile(options,mission,vol_flow,i,n);
    end
end
for i = 1:1:m
    for j = 1:1:n
        battery_kJ(i,j) = battery(n*(i-1)+j);
        weight.fuel(i,j) = fuel(n*(i-1)+j);
        param.power_mission(i,j,:) = P_sys_mission(n*(i-1)+j,:);
        param.efficiency_mission(i,j,:) = eff_mission(n*(i-1)+j,:);
        param.FCV_mission(i,j,:) = FCV_mission(n*(i-1)+j,:);
        param.FCiden_mission(i,j,:) = FCiden_mission(n*(i-1)+j,:);
        param.TSFC_mission(i,j,:) = TSFC_mission(n*(i-1)+j,:);
    end
end
weight.fuel_burn = weight.fuel; 
weight.fuel_stored = weight.fuel.*options.fuel_tank_mass_per_kg_fuel + res_fuel/3; %Total LH2 storage including weight of insulated container and equivalent energy reserve storage
weight.battery = battery_kJ./options.battery_specific_energy; %battery weight required to assist with takeoff assuming battery energy storage of 1260 kJ/kg;
weight.total = (weight.sofc + weight.otm + weight.comp + weight.turb + weight.hx + weight.motor + weight.battery + weight.propulsor + weight.fuel_stored); 
param.weight = weight;
param.P_den = param.NetPower./(weight.sofc + weight.otm + weight.comp + weight.turb + weight.hx);
end%Ends function run_cycle

function [fuel,battery,P_sys_mission,eff_mission,FCV_mission,FCiden_mission,TSFC_mission] = flight_profile(options,mission,vol_flow,par_i,n)
fuel = 0;
battery = 0;
alt_tab = [0:200:7000,8000,9000,10000,12000,14000];%
atmosphere_density = [1.225,1.202,1.179,1.156,1.134,1.112,1.090,1.069,1.048,1.027,1.007,0.987,0.967,0.947,0.928,0.909,0.891,0.872,0.854,0.837,0.819,0.802,0.785,0.769,0.752,0.736,0.721,0.705,0.690,0.675,0.660,0.646,0.631,0.617,0.604,0.590,0.526,0.467,0.414,0.312,0.228]'; %Density, kg/m^3

i = ceil(par_i/n);
j = par_i-n*(i-1);
f = fieldnames(options);
nn = length(mission.alt);
mm = 12;
for k = 1:1:length(f)
    options2.(f{k}) = ones(mm,nn)*options.(f{k})(i,j);
end
vol_flow2 = vol_flow(i,j)*[1;.9;.8;.7;.5; .5*ones(mm-5,1);]*ones(1,nn);%reduce volume flow to 50%, then increase P_perm to reduce oxygen and power
options2.height = ones(mm,1)*mission.alt'; %Altitude, meters
air_den = interp1(alt_tab,atmosphere_density,options2.height);
molar_flow2 = vol_flow2.*air_den/28.84;%Flow rate at altitude assuming constant volumetric flow device
[A1,~] = std_atmosphere(options2.height,molar_flow2);%Ambient conditions as a function of altitude
for k = 1:1:nn
    options2.P_perm(:,k) = [50*ones(5,1);logspace(log10(50),log10(0.99*.21*A1.P(1,k)*options2.PR_comp(1,1)),mm-5)']; %Pressure of OTM oxygen stream, kPa; 
end
[A2,C1] = compressor(A1,options2.PR_comp.*A1.P,options2.C1_eff);
[OTM,C2,A3,A4,O1,O2,O3,O4,O5] = OxygenModule(options2,A2);
%adjust permeate pressure to be within feasible oxygen output range for SOFC area
min_O2 = 0.1*options2.SOFC_area(1,1)*10000/(96485.33*4000);
max_O2 = .5./options2.asr(1,1).*options2.SOFC_area(1,1)*10000/(96485.33*4000);%Cant solve for ultra low or high current densities
if any(any(O5.O2>max_O2)) || any(any(O5.O2<min_O2))
    R1 = max_O2./O5.O2;
    R2 = min_O2./O5.O2;
    options2.P_perm = min(max(options2.P_perm,(0.21*options2.PR_comp.*A1.P).^(1-R1).*options2.P_perm.^R1),(0.21*options2.PR_comp.*A1.P).^(1-R2).*options2.P_perm.^R2);
    for k = 1:1:nn
        options2.P_perm(:,k) = linspace(min(options2.P_perm(:,k)),max(options2.P_perm(:,k)),mm);
    end
    [OTM,C2,A3,A4,O1,O2,O3,O4,O5] = OxygenModule(options2,A2);
end
[A5,T1] = expander(A4,A1.P,options2.T1_eff);
[FC,E1,F5] = oxy_fuelcell(options2,O5);
[FL,B1,F2,F3,F4,E2,E3,E4,HX] = fuel_loop(options2,E1,F5,A1);
P_sys = FC.Power + C1.work + C2.work + T1.work + B1.work;

P_shaft = options2.motor_eff.*P_sys;
fuel_for_OTM_preheat = -min(0,FC.Qremove - OTM.heat_added)./FC.hrxnmol;
FTE = P_sys./(FC.H2_used.*FC.hrxnmol + fuel_for_OTM_preheat.*FC.hrxnmol);
FCV = FC.V;
iden = FC.i_den;
P_sys_mission = zeros(1,nn);
eff_mission = zeros(1,nn);
FCV_mission = zeros(1,nn);
FCiden_mission = zeros(1,nn); 
TSFC_mission = zeros(1,nn);
%find permeate pressure condition that results in correct power for each flight segment
for k = 1:1:nn
    P_req = mission.power(i,j,k);%shaft power in kW.  
    if P_req>max(P_shaft(:,k))
        [P,I] = max(P_shaft(:,k));
        battery = battery + (P_req - P)*mission.duration(k)*3600;
        fuel = fuel + (FC.H2_used(I,k)+fuel_for_OTM_preheat(I,k))*2*mission.duration(k)*3600;
        P_sys_mission(k) = P_sys(I,k);
        eff_mission(k) = FTE(I,k);
        FCV_mission(k) = FC.V(I,k);
        FCiden_mission(k) = FC.i_den(I,k);
        TSFC_mission(k) = fuel./(mission.thrust(k).*mission.duration(k)); % SFC in kg/N*hour; 
    elseif P_req<min(P_shaft(:,k))
        [h2_use,I] = min(FC.H2_used(:,k));
        fuel = fuel + P_req/P_shaft(I,k)*(FC.H2_used(I,k)+fuel_for_OTM_preheat(I,k))*2*mission.duration(k)*3600;
        P_sys_mission(k) = P_req/min(P_sys(:,k))*P_sys(I,k);
        eff_mission(k) = FTE(I,k);
         FCV_mission(k) = FC.V(I,k);
         FCiden_mission(k) = FC.i_den(I,k);
         TSFC_mission(k) = fuel./(mission.thrust(k).*mission.duration(k)); 
    else
        fuel = fuel + (interp1(P_shaft(:,k),FC.H2_used(:,k),P_req)+interp1(P_shaft(:,k),fuel_for_OTM_preheat(:,k),P_req))*2*mission.duration(k)*3600;
        P_sys_mission(k) = interp1(P_shaft(:,k),P_sys(:,k),P_req);
        eff_mission(k) = interp1(P_shaft(:,k),FTE(:,k),P_req);
        FCV_mission(k) = interp1(P_shaft(:,k),FCV(:,k),P_req);
        FCiden_mission(k) =interp1(P_shaft(:,k),iden(:,k),P_req);
        TSFC_mission(k) = fuel./(mission.thrust(k).*mission.duration(k)); 
    end
end
end%Ends function flight_profile