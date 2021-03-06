function CpT = SpecHeat(varargin) % Specific heat 
%Returns specific heat in kJ/kmol*K
% Option 1: provide a vector of temperatures and it returns specific heat at those temperatures for all species CH4, CO, CO2, H2, H2O, N2, O2, C, NO, OH, H
% Option 2: provide a vector of temperatures and a cell array of strings for the species of interest
% Option 3: provide a structure where __.T coresponds to temperature, ___.CH4 coresponds to the flow rate of methane ____.H2 to the flow rate of hydrogen...
JJ = varargin{1};
[m,n] = size(JJ.T);
CPnet = zeros(m,n); 

for u = 1:n
if isfield(varargin{1},'T')
    In = varargin{1};
    Inlet.T= In.T(1:m,u);
    T = Inlet.T;
    if isfield(varargin{1},'N2')
        Inlet.N2 = In.N2(1:m,u);
    end
    if isfield(varargin{1},'O2')
        Inlet.O2 = In.O2(1:m,u);
    end
    if isfield(varargin{1},'H2O')
        Inlet.H2O = In.H2O(1:m,u);
    end
    if isfield(varargin{1},'H2')
        Inlet.H2 = In.H2(1:m,u);
    end
else
    T = varargin{1};
end

if isstruct(varargin{1})
    %Inlet=  Inlet;%varargin{1};
    T = Inlet.T;
    spec = fieldnames(Inlet);
    spec = spec(~strcmp('T',spec)); 
    spec = spec(~strcmp('P',spec)); 
elseif isnumeric(varargin{1})
    T = varargin{1};
    if length(varargin)==2
        spec = varargin{2};
    else
        spec = {'CH4';'CO';'CO2';'H2';'H2O';'N2';'O2';'H';'OH';'C';'NO';};
    end
end

T1 = ones(length(T),1);
T2 = (T/1000);
T3 = ((T/1000).^2); 
T4 = ((T/1000).^3); 
T5 = 1./((T/1000).^2);

for i = 1:1:length(spec)
    switch spec{i}
        case 'CH4'
            A = [85.81217,11.26467,-2.114146,0.138190,-26.42221,-153.5327,224.4143];
            B = [-0.703029,108.4773,-42.52157,5.862788,0.678565,-76.84376,158.7163];
            C = (T>1300)*A+(T<=1300)*B;
        case 'CO'
            A = [35.15070,1.300095,-.205921,0.013550,-3.282780,-127.8375,231.7120];
            B = [25.56759,6.096130,4.054656,-2.671301,0.131021,-118.0089,227.3665;];
            C = (T>1300)*A+(T<=1300)*B;
        case 'CO2'
            A = [58.16639,2.720074,-0.492289,0.038844,-6.447293,-425.9186,263.6125;];
            B = [24.99735,55.18696,-33.69137,7.948387,-0.136638,-403.6075,228.2431;];
            C = (T>1200)*A+(T<=1200)*B;
        case 'H2'
            A = [43.413560,-4.293079,1.272428,-.096876,-20.533862,-38.515158,162.081354;];
            B = [18.563083,12.257357,-2.859786,0.268238,1.977990,-1.147438,156.288133;];
            D = [33.066178,-11.363417,11.432816,-2.772874,-0.158558,-9.980797,172.707974;];
            C = (T>2500)*A+(T<=2500).*(T>1000)*B+(T<=1000)*D;
        case 'H2O'
            A = [41.96426,8.622053,-1.499780,0.098119,-11.15764,-272.1797,219.7809;];
            B = [30.09200,6.832514,6.793435,-2.534480,0.082139,-250.8810,223.3967;];
            C = (T>1700)*A+(T<=1700)*B;
        case 'N2'
            A = [35.51872,1.128728,-0.196103,0.014662,-4.553760,-18.97091,224.9810;];
            B = [19.50583,19.88705,-8.598535,1.369784,0.527601,-4.935202,212.3900;];
            D = [28.98641,1.853978,-9.647459,16.63537,0.000117,-8.671914,226.4168;];
            C = (T>2000)*A+(T<=2000).*(T>500)*B+(T<=500)*D;
        case 'O2'
            A = [20.91111,10.72071,-2.020498,0.146449,9.245722,5.337651,237.6185;];
            B = [30.03235,8.772972,-3.988133,0.788313,-0.741599,-11.32468,236.1663;];
            D = [31.32234,-20.23531,57.86644,-36.50624,-0.007374,-8.903471,246.7945;];
            C = (T>2000)*A+(T<=2000).*(T>700)*B+(T<=700)*D;
        case 'C'
            C = [21.1751,-0.812428,0.448537,-0.043256,-0.013103,710.347,183.8734];
        case 'NO'
            A = [35.99169,0.95717,-0.148032,0.009974,-3.004088,73.10787,246.1619];
            B = [23.83491,12.58878,-1.139011,-1.497459,0.21419,83.35783,237.1219];
            C = (T>1200)*A+(T<=1200)*B;
        case 'OH'
            A = [28.74701,4.7144,-0.814725,0.054748,-2.747829,26.41439,214.1166];
            B = [32.27768,-11.36291,13.60545,-3.846486,-0.001335,29.75113,225.5783];
            C = (T>1300)*A+(T<=1300)*B;
        case 'H'
            C =[20.78603,4.85E-10,-1.58E-10,1.53E-11,3.20E-11,2.12E+02,1.40E+02];
        case 'C2H6'
            C =[6.9,172.7,-64.06,7.285,9.173,0,0,0];
        case 'C3H8'
            C =[-4.04,304.8,-157.2,31.74,11.05,0,0,0];
        case 'C6H6'
            C =[-50.24,568.2244,-442.503,134.5489,6.6206,0,0,0];
    end
    Cp.(spec{i}) = T1.*C(:,1) + T2.*C(:,2) + T3.*C(:,3) + T4.*C(:,4) + T5.*C(:,5);
end

if exist('Inlet','var')
    Flow = net_flow(Inlet);
    %CPnet =0;
    for i = 1:1:length(spec)
        CPnet(1:m,u) = CPnet(1:m,u) + Cp.(spec{i}).*Inlet.(spec{i})./Flow;
    end
end
    
end
CpT = CPnet;
