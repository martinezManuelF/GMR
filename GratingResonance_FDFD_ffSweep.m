%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Resonance Grating - FDFD Simulation
%       This MATLAB files simulates a single period of a rectangular
%       grating using the Finite-Difference Frequency Domain method.
%       The wavelength sweep goes from 2 um to 1 um.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set(0,'DefaultFigureWindowStyle','docked');

% close all;
clc;
clear all;
close all;

% UNITS
micrometers = 1;
millimeters = 1e3 * micrometers;
meters = 1e3 * millimeters;
degrees = pi/180;
seconds = 1;
hertz = 1/seconds;
gigahertz = 1e9 * hertz;

% CONSTANTS
c0 = 299792458 * meters/seconds;

% POINTS FOR SWEEP 
Nf = 501;
tot_ref = zeros(1,Nf);
tot_trn = tot_ref;
tot_con = tot_ref;

% FIGURE SETTINGS 
fig = 0;        % 0 for no figures, 1 for figure animation

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% DEFINE SIMULATION PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SOURCE PARAMETERS
SRC.lam0 = 1.55 * micrometers;    % Free space wavelength
SRC.theta = 0 * degrees;
SRC.MODE = 'E';                   % EM mode
f0 = c0/SRC.lam0;
lam01 = 1.4 * micrometers;
lam02 = 1.7 * micrometers;
lam0 = linspace(lam01,lam02,Nf);

% GRATING PARAMETERS
lamd = 1.55 * micrometers;      % Design wavelength
fd   = c0/lamd;                 % Design frequency
ur   = 1.0;                     % Grating permeability
er   = 2.0;                     % Grating permittivity
nr   = sqrt(ur*er);             % Substrate refractive index 
w    = 0.5000*lamd;             % Tooth width
L    = 0.8621*lamd;             % Grating period
d    = 0.1500*lamd;             % Grating depth
t    = lamd/(2*nr);             % Substrate thickness

% EXTERNAL MATERIALS
ur1 = 1.0;                    % Reflection region permeability
er1 = 1.0;                    % Reflection region permittivity
ur2 = 1.0;                    % Transmission region permeability
er2 = 1.0;                    % Transmission region permittivity

% GRID PARAMETERS
NRES = 60;                    % Grid resolution
BUFZ = 2*lam02 * [1 1];       % Spacer region above and below grating
DEV.NPML = [20 20];           % Size of PML at top and bottom of grid

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CALCULATE OPTIMIZED GRID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate refractive indices
ndev = sqrt(ur*er);
nref = sqrt(ur1*er1);
ntrn = sqrt(ur2*er2);

% Consider wavelengths
lam_min = min([lam01 lam02])/max([ndev nref ntrn]);
dlam = lam_min/NRES; 

% Consider mechanical parameters
dmin = w;            % x2 is the smallest defined distance
dd = dmin/2;   % Delta for distance

% Choose the highest resolution
dx = dlam;
dy = dx;

% Snap grid to critical dimension (in this case L and d+t)
Nx = 2*ceil(L/dx/2) + 1;      % First guess at grid spacing (odd for periodic)
Ny = ceil((d+t)/dy);

% Calculate new grid resolutions
dx = L/Nx;
dy = (d+t)/Ny;

% Incorporate PML and spacer regions
Ny = Ny + DEV.NPML(1) + DEV.NPML(2) + ceil(BUFZ(1)/dy) + ceil(BUFZ(2)/dy);

% Calculate 2x grid
Nx2 = 2*Nx;
Ny2 = 2*Ny;
dx2 = dx/2;
dy2 = dy/2;
DEV.RES = [dx2,dy2];
xa2 = [0:Nx2-1]*dx2;
ya2 = [0:Ny2-1]*dy2;

f = linspace(0.01,0.99,Nf);
for n = 1:Nf
    ff = f(n);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% BUILD DEVICE ON 2x GRID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
UR2 = ur1*ones(Nx2,Ny2);
ER2 = er1*ones(Nx2,Ny2);

% Calculate start and stop indices for filling in the grid
nt1 = 2*DEV.NPML(1) + ceil(BUFZ(1)/dy2);
nt2 = nt1 + round(t/dy2) - 1;
% nd1 = round((nt2+nt1)/2);
% nd2 = nt2;
nd2 = nt2;
nd1 = nt2 - round(d/dy2);
nx1 = round(Nx2*ff/2);
nx2 = round(Nx2 - Nx2*ff/2);

% Fill in the permeability regions
UR2(:,:) = ur;

% Fill in the permittivity regions
ER2(:,nt1:nt2) = er;
ER2(nx1:nx2,nd1:nd2) = 1;


DEV.UR2 = fliplr(UR2);
DEV.ER2 = fliplr(ER2);


% figure('color','w');
if fig
    subplot(121);
end
imagesc(xa2,ya2,DEV.ER2');
title('\epsilon_r');
xlabel('x (\mum)'); ylabel('y (\mum)');
colorbar;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% IMPLEMENT FDFD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    tic;
    SRC.lam0 = lam0(n);         %angle of incidence
    DAT = fdfd2d(DEV,SRC);
    tot_ref(n) = DAT.REF;
    tot_trn(n) = DAT.TRN;
    tot_con(n) = DAT.CON;
    clc;
    time = toc;
    min = floor(time*(Nf-n)/60);
    sec = round((time*(Nf-n)/60 - min)*60);
    disp(['Estimated Time: ' num2str(min) ' minutes '...
            num2str(sec) ' seconds']);
    disp([num2str(n) ' out of ' num2str(Nf) ' Iterations']);
%     figure(1);
%     plot(theta(1:n)./degrees,100.*tot_ref(1:n),'r','linewidth',2);
%     hold on;
%     plot(theta(1:n)./degrees,100.*tot_trn(1:n),'b','linewidth',2);
%     plot(theta(1:n)./degrees,100.*tot_con(1:n),'g','linewidth',2);
%     hold off;
%     title('Device Behavior');
%     xlabel('Angle of Incidence (degrees)'); ylabel('Power');
%     xlim([theta(1) theta(end)]./degrees); ylim([0 102]);
%     drawnow;
    
%     figure(1);
%     subplot(131);
%     imagesc(dx2.*[-floor(Nx2/2),floor(Nx2/2)],dy.*[0,Ny-1],DEV.UR2'); 
%     title('\mu_{r}');
%     xlabel('x (cm)'); ylabel('y (cm)'); caxis([1 10]);
%     colorbar;
%     axis equal tight;
% 
%     subplot(132);
%     imagesc(dx2.*[-floor(Nx2/2),floor(Nx2/2)],dy.*[0,Ny-1],DEV.ER2'); 
%     title('\epsilon_{r}');
%     xlabel('x (cm)'); ylabel('y (cm)'); caxis([1 10]);
%     colorbar;
%     axis equal tight;
    if fig
        subplot(122);
        imagesc(dx.*[0,Nx-1],dy.*[0,Ny-1],real(DAT.F)'); 
        title([SRC.MODE ' Mode @ ' num2str(SRC.lam0) ' \mum']);
        shading interp;
        xlabel('x (\mum)'); ylabel('y (\mum)');
        colorbar;
    %     axis equal tight;
        drawnow;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% DISPLAY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disp('DASHBOARD PARAMETERS:');
disp(['Source Frequency = ' num2str(f0(end)./gigahertz) ' GHz']);
disp(['Angle of Incidence = ' num2str(SRC.theta./degrees) ' degrees']);
disp(['Electromagnetic Mode = ' SRC.MODE]);
disp(['Device Design Frequency = ' num2str(fd./gigahertz) ' GHz']);
disp(['w = ' num2str(w./micrometers) ' mm']);
disp(['L = ' num2str(L./micrometers) ' mm']);
disp(['d = ' num2str(d./micrometers) ' mm']);
disp(['t = ' num2str(t./micrometers) ' mm']);
disp(['ur = ' num2str(ur)]);
disp(['er = ' num2str(er)]);
disp(['ur1 = ' num2str(ur1)]);
disp(['er1 = ' num2str(er1)]);
disp(['ur2 = ' num2str(ur2)]);
disp(['er2 = ' num2str(er2)]);
disp(['NRES = ' num2str(NRES)]);
disp(['BUFZ = [' num2str(BUFZ(1)/SRC.lam0) ' ' num2str(BUFZ(2)/SRC.lam0) ']*lam0']);
disp(['NPML = [' num2str(DEV.NPML(1)) ' ' num2str(DEV.NPML(2)) ']']);
disp(' ');

ref_diff_orders = find(DAT.RDE);
trn_diff_orders = find(DAT.TDE);
disp('REFLECTION DIFFRACTION ORDERS:');
for n = ref_diff_orders(1):ref_diff_orders(end)
    disp(['RDE(' num2str(n - ceil(Nx/2)) ') = ' num2str(100*DAT.RDE(n)) '%']);
end
disp(' ');
disp('TRANSMISSION DIFFRACTION ORDERS:');
for n = trn_diff_orders(1):trn_diff_orders(end)
    disp(['TDE(' num2str(n - ceil(Nx/2)) ') = ' num2str(100*DAT.TDE(n)) '%']);
end
disp(' ');

disp('OVERALL:');
disp(['REF = ' num2str(100*DAT.REF) '%']);
disp(['TRN = ' num2str(100*DAT.TRN) '%']);
disp(['CON = ' num2str(100*DAT.CON) '%']);

figure('color','white');
plot(f,100.*tot_ref,'r','linewidth',2);
hold on;
plot(f,100.*tot_trn,'b','linewidth',2);
plot(f,100.*tot_con,'--k','linewidth',2);
hold off;
title([SRC.MODE ' Mode Fill Fraction Sweep']);
xlabel('Fill Fraction'); ylabel('Power (%)');
legend('Reflectance','Transmittance','Conservation');
% xlim([lam0(1) lam0(end)]./micrometers); 
ylim([0 102]);




