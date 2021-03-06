%%  Test Cycle
n1 = 10; % number of points in test dimension 1
n2 = 10; % number of points in test dimension 2
options.airflow = ones(n1,n2); %Initial airflow, kmol/s
options.SOFC_area = linspace(2e3,5e3,n1)'*ones(1,n2); %membrane area in m^2 per kmol airflow
options.dT_fc = 50*ones(n1,n2); %Maximum temperature differential, Kelvin
options.asr = 0.25*ones(n1,n2); % Area specific resistance, ohm-cm^2
options.T_fc = 1023*ones(n1,n2); %Inlet temperature for SOFC
options.spu = 0.2*ones(n1,n2); 
options.steamratio = 0.05*ones(n1,n2); %Percentage of humidification at fuel inlet
options.PR_comp = ones(n1,1)*linspace(12,48,n2); %Range of intake pressures for OTM, kPa
options.T_motor = 77*ones(n1,n2); %temperture of H2 gas after cooling superconducting motors
options.C1_eff = 0.80*ones(n1,n2); %Mechanical efficiency of compressor 1
options.T1_eff = 0.88*ones(n1,n2); %Mechanical efficiency of turbine
options.Blower_eff = 0.5*ones(n1,n2); %efficiency of blower
options.Blower_dP = 20*ones(n1,n2); %Pressure rise in blower in kPa
options.prop_eff = 0.80*ones(n1,n2);%propulsor efficiency
options.motor_eff = 0.984*ones(n1,n2);%motor efficiency

%%OTM cycle specific parameters
options.P_fc = 1000*ones(n1,n2); %Operating pressure for SOFC
options.OTM_area = 1e3*ones(n1,n2); %membrane area in m^2 per kmol airflow
options.T_otm = options.T_fc; %Operating temperature for OTM
options.j0_otm = 7*ones(n1,n2); %Nominal oxygen flux through OTM NmL/cm^2*min
options.P0_otm = 2.1*ones(n1,n2); %Nominal oxygen pressure ratio across OTM (total pressure ratio *.21)
options.T_oxygen_pump = 323*ones(n1,n2); %Inlet temperature of vacuum pump
options.P_perm = 75*ones(n1,n2); %Pressure of OTM oxygen stream, kPa; 
options.C2_eff = 0.80*ones(n1,n2); %Mechanical efficiency of compressor 2 propulsor portion (30%) of 4 RR RB-211 engines


%% system mass parameters
options.motor_power_den = 24*ones(n1,n2); %Power density of HTSM
options.OTM_specific_mass = 0.05987*10000/81*ones(n1,n2); %Weight per m^2 OTM membrane, kg:  assumes 0.05987kg/ 81cm^2 cell, 0.87 mm repeating unit height
options.heat_pipe_specific_mass = 1./1.72*ones(n1,n2); %Weight per kW of heat transfer
options.sofc_specific_mass = 0.06925*10000/81*ones(n1,n2); %Weight per m^2, kg:  assumes 0.06925kg/ 81cm^2 cell, 0.9615mm repeating unit height
options.fuel_tank_mass_per_kg_fuel = 1*ones(n1,n2); %Weight kg  (did you subtract the regular fuel tank weight?)
options.battery_specific_energy = 1260*ones(n1,n2); %kJ / kg
options.hx_U = 40*ones(n1,n2); %Upper heat transfer performance of a gas-to-gas counterflow HX based on Heat and Mass transfer, Cengel, 4e
options.hx_t = 0.0018*ones(n1,n2); %Total thickness of plates and housing in m, based on NASA estimates, 2005
options.hx_mat_density = 2700*ones(n1,n2); %Density of sintered silicon carbide, kg/m^3, chosen to replace SS 304 in NASA estimates with same plate and housing thickness
options.safety_factor = 1.05*ones(n1,n2); %Safety factor on power plant sizing

%% 787-8 Standard Case in Piano_X
[segment,history,profile] = import_flight_txt('787');
TO_weight = 219539;% Initial mass at condition 1
StandardPayload = 23052;% kg
FuelUsed = 75126;% kg, block summary end
Range = 14187;% km
engine_mass = 6033; %Trent 1000 engine, EASA certification
res_fuel = 7799; %res fuel
options.engine_radius = 2.8*ones(n1,n2); %
options.num_engines = 2*ones(n1,n2);
options.electric_demand = 500*ones(n1,n2); %Ancilliary demand, kW

%% %Airbus A380 Standard Case in Piano_X
% [segment,history,profile] = import_flight_txt('A380F');
% TO_weight = 569000;% kg, Initial mass at condition 1
% StandardPayload = 52725; %kg, Piano default design
% FuelUsed = 211418;% kg, Piano block summary, end
% Range = 14408;% nm, Piano default design
% engine_mass = 6246; % kg,Trent 900 EASA certification
% res_fuel = 22356; %kg
% options.engine_radius = 2.5*ones(n1,n2); %
% options.num_engines = 4*ones(n1,n2);
% options.electric_demand = 1000*ones(n1,n2); %Ancilliary demand, kW

%% Airbus A300 600R, Standard case in Piano X
% [segment,history,profile] = import_flight_txt('A300');
% TO_weight = 170500;% kg, Initial mass at condition 1
% StandardPayload = 25365; %kg, Piano default design
% FuelUsed = 48012;% kg, Piano block summary, end
% Range = 7247;% km, Piano default design
% engine_mass = 5092; % kg,GE CF6 EASA certification
% res_fuel= 7537; %Reserve fuel, kg
% options.engine_radius = 2.5*ones(n1,n2); %
% options.num_engines = 2*ones(n1,n2);
% options.electric_demand = 300*ones(n1,n2); %Ancilliary demand, kW

%% Fokker F70, Standard case in Piano X
% [segment,history,profile] = import_flight_txt('F70');
% TO_weight = 36741;% kg, Initial mass at condition 1
% StandardPayload = 7167; %kg, Piano default design
% FuelUsed = 4917;% kg, Piano block summary, end
% Range = 2020;% km, Piano default design
% num_engines = 2;
% engine_mass = 1501; % kg,RR tay 620-15 EASA certification+
% res_fuel = 2136; %kg
% options.engine_radius = 2*ones(n1,n2); %
% options.num_engines = 2*ones(n1,n2);
% options.electric_demand = 100*ones(n1,n2); %Ancilliary demand, kW

%%%
options.air_frame_weight = (TO_weight - FuelUsed - res_fuel - StandardPayload - options.num_engines*engine_mass);%airframe mass in kg:
options.propulsor_weight = 0.3*options.num_engines*engine_mass; %Weight propulsor portion (30%) 

%% all parameters of mission must be the same length, design_point is the index of the mission profile for whitch the nominal power is scaled
mission.alt = (segment.initial_alt + [segment.initial_alt(2:end);0])/2; %average altitude for segment (m)
mission.duration = (segment.end_time - [0;segment.end_time(1:end-1)])/60; %duration for segment (hrs)
mission.thrust = zeros(n1,n2,length(mission.alt));
for i = 1:1:length(mission.alt)
    mission.mach_num(i,1) = mean(nonzeros(history.mach(i,:)));
	mission.thrust(:,:,i) = abs(mean(nonzeros(history.FN_eng(i,:))))*options.num_engines;%thrust profile in N
end
%[z1,z2] = size(mission.alt);
%[s1,s2] = max(max(mission.alt);
[w1,w2] = max(max(mission.alt)); 
[w3,w4] = find(mission.alt ==w1);
z1 = w3;
Weight = zeros(10,z1);
performance_dp = zeros(8,z1);
performance_to = zeros(8,z1)
for l = 8:8
mission.design_point = l;%%change based on mission profile

tic
param = run_cycle(options,mission,res_fuel);
toc
param.weight.payload = TO_weight - options.air_frame_weight - param.weight.total;
payload = param.weight.payload;
[performancetable,weighttable] = collector(param,mission);
performance_dp(:,l) = performancetable.PASTEdp;
performance_to(:,l) = performancetable.PASTEto;
Weight(:,l) = weighttable.PASTE; 
end
% payload(payload<0.8*mean(mean(param.weight.payload))) = nan;
% figure(3)
% % param.weight.payload = TO_weight - options.air_frame_weight - param.weight.total;
% % payload = param.weight.payload;
% % [performancetable,weighttable] = collector(param,mission);
% % payload(payload<0.8*mean(mean(param.weight.payload))) = nan;
% % figure(3)
% ax = surf(options.PR_comp,param.i_den,payload);
% xlabel(ax,'Compressor pressure ratio');
% ylabel(ax,'SOFC current density (A/cm^2)');
% zlabel(ax,'payload (kg)');