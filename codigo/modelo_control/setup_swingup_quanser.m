%% SETUP_SWINGUP_QUANSER  Parametros de referencia del swing-up (QUBE-Servo, Quanser).
%  Version espejo del ejemplo estudiantil de Quanser: carga los parametros del pendulo
%  rotatorio (parametros_rotpen_quanser) y calcula Jp_cm para el control de swing-up
%  basado en energia. Antes: setup_swingup_student.m.
% Load model parameters
parametros_rotpen_quanser;
% Moment of inertia of pendulum about center of mass (kg-m^2)
Jp_cm = mp*Lp^2/12; % used to calculate pendulum energy in swing-up control
%