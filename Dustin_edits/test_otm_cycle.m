%%  Test Cycle
n1 = 10; % number of points in test dimension 1
n2 = 10; % number of points in test dimension 2
options.airflow = ones(n1,n2); %Initial airflow, kmol/s
options.SOFC_area = linspace(1e3,5e3,n1)'*ones(1,n2); %membrane area in m^2 per kmol airflow
options.dT_fc = 50*ones(n1,n2); %Maximum temperature differential, Kelvin
options.asr = 0.15*ones(n1,n2); % Area specific resistance, ohm-cm^2
options.P_fc = 1000*ones(n1,n2); %Operating pressure for SOFC
options.T_fc = 1023*ones(n1,n2); %Inlet temperature for SOFC
options.spu = 0.2*ones(n1,n2); 
options.steamratio = 0.01*ones(n1,n2); %Percentage of humidification at fuel inlet
options.PR_comp = ones(n1,1)*linspace(15,60,n2); %Range of intake pressures for OTM, kPa
options.T_motor = 77*ones(n1,n2); %temperture of H2 gas after cooling superconducting motors
options.C1_eff = 0.80*ones(n1,n2); %Mechanical efficiency of compressor 1
options.T1_eff = 0.88*ones(n1,n2); %Mechanical efficiency of turbine
options.Blower_eff = 0.5*ones(n1,n2); %efficiency of blower
options.Blower_dP = 20*ones(n1,n2); %Pressure rise in blower in kPa
options.prop_eff = 0.95*ones(n1,n2);%propulsor efficiency
options.motor_eff = 0.984*ones(n1,n2);%motor efficiency
options.OTM_area = 2e3*ones(n1,n2); %membrane area in m^2 per kmol airflow
options.T_otm = options.T_fc; %Operating temperature for OTM
options.j0_otm = 7*ones(n1,n2); %Nominal oxygen flux through OTM NmL/cm^2*min
options.P0_otm = 2.1*ones(n1,n2); %Nominal oxygen pressure ratio across OTM (total pressure ratio *.21)
options.T_oxygen_pump = 323*ones(n1,n2); %Inlet temperature of vacuum pump
options.P_perm = 50*ones(n1,n2); %Pressure of OTM oxygen stream, kPa; 
options.C2_eff = 0.80*ones(n1,n2); %Mechanical efficiency of compressor 2 propulsor portion (30%) of 4 RR RB-211 engines
options.prop_eff = 0.95*ones(n1,n2);%propulsor efficiency
options.motor_eff = 0.986*ones(n1,n2);%motor efficiency

%% system mass parameters
options.motor_power_den = 24*ones(n1,n2); %Power density of HTSM
options.OTM_specific_mass = 0.048907*10000/81*ones(n1,n2); %Weight per m^2 OTM membrane, kg:  assumes 0.048907kg/ 81cm^2 cell
options.sofc_specific_mass = 0.05508*10000/81*ones(n1,n2); %Weight per m^2, kg:  assumes 0.05508kg/ 81cm^2 cell
options.fuel_tank_mass_per_kg_fuel = ones(n1,n2); %Weight kg  (did you subtract the regular fuel tank weight?)
options.battery_specific_energy = 1260*ones(n1,n2); %kJ / kg

%% aircraft specific parameters
%787-8 Standard Case in Piano_X
[segment,history,profile] = import_flight_txt('787');
TO_weight = 254011;% kg From 747-8 airport planning guides
StandardPayload = 23052;% kg
FuelUsed = 75126;% kg
Range = 7661;% nm
num_engines = 2;
engine_mass = 6033;
RRTrent1000engine = 2*6033*ones(n1,n1);% kg

%%%
options.air_frame_weight = (options.TO_weight - FuelUsed - StandardPayload - num_engines*engine_mass)*ones(n1,n2);%airframe mass in kg:
options.propulsor_weight = 0.3*num_engines*engine_mass*ones(n1,n2); %Weight propulsor portion (30%) 

%% all parameters of mission must be the same length, design_point is the index of the mission profile for whitch the nominal power is scaled
mission.alt = (segment.initial_alt + [segment.initial_alt(2:end);0])/2; %average altitude for segment (m)
mission.duration = (segment.end_time - [0;segment.end_time(1:end-1)])/60; %duration for segment (hrs)
for i = 1:1:length(mission.alt)
    mission.mach_num(i,1) = mean(nonzeros(history.mach(i,:)));
	mission.thrust(:,:,i) = ones(n1,n2)*mean(nonzeros(history.FN_eng(i,:)))*num_engines;%thrust profile in N
end
mission.design_point = 3;%%change based on mission profile

tic
param = run_cycle(options,mission);
toc

param.weight.payload = options.TO_weight - options.air_frame_weight - param.weight.total;
payload = param.weight.payload;
payload(payload<0.8*mean(mean(param.weight.payload))) = nan;
figure(3)
ax = surf(options.PR_comp,param.i_den,payload);
% xlabel(ax,'Compressor pressure ratio');
% ylabel(ax,'SOFC current density (A/cm^2)');
% zlabel(ax,'payload (kg)');