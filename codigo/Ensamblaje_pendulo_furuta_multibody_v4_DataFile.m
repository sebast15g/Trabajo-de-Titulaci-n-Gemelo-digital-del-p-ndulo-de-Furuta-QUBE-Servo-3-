% Simscape(TM) Multibody(TM) version: 25.1

% This is a model data file derived from a Simscape Multibody Import XML file using the smimport function.
% The data in this file sets the block parameter values in an imported Simscape Multibody model.
% For more information on this file, see the smimport function help page in the Simscape Multibody documentation.
% You can modify numerical values, but avoid any other changes to this file.
% Do not add code to this file. Do not edit the physical units shown in comments.

%%%VariableName:smiData


%============= RigidTransform =============%

%Initialize the RigidTransform structure array by filling in null values.
smiData.RigidTransform(11).translation = [0.0 0.0 0.0];
smiData.RigidTransform(11).angle = 0.0;
smiData.RigidTransform(11).axis = [0.0 0.0 0.0];
smiData.RigidTransform(11).ID = "";

%Translation Method - Cartesian
%Rotation Method - Arbitrary Axis
smiData.RigidTransform(1).translation = [26.200000000000273 21.749999999999506 -2.1148416351479682e-11];  % mm
smiData.RigidTransform(1).angle = 2.0943951023936616;  % rad
smiData.RigidTransform(1).axis = [0.57735026918978116 0.57735026918978105 0.5773502691893152];
smiData.RigidTransform(1).ID = "B[hub_soporte_enc-2:-:brazo_pendulo-4]";

%Translation Method - Cartesian
%Rotation Method - Arbitrary Axis
smiData.RigidTransform(2).translation = [-1.4210854715210356e-14 9.2559071906198868e-18 -1.021231290852921e-14];  % mm
smiData.RigidTransform(2).angle = 2.0943951023931957;  % rad
smiData.RigidTransform(2).axis = [0.57735026918962584 0.57735026918962584 0.57735026918962562];
smiData.RigidTransform(2).ID = "F[hub_soporte_enc-2:-:brazo_pendulo-4]";

%Translation Method - Cartesian
%Rotation Method - Arbitrary Axis
smiData.RigidTransform(3).translation = [0 100.59999999999999 0];  % mm
smiData.RigidTransform(3).angle = 2.0943951023931953;  % rad
smiData.RigidTransform(3).axis = [-0.57735026918962584 -0.57735026918962584 -0.57735026918962584];
smiData.RigidTransform(3).ID = "B[base_qube-1:-:hub_soporte_enc-2]";

%Translation Method - Cartesian
%Rotation Method - Arbitrary Axis
smiData.RigidTransform(4).translation = [0 0 0];  % mm
smiData.RigidTransform(4).angle = 2.0943951023931953;  % rad
smiData.RigidTransform(4).axis = [-0.57735026918962584 -0.57735026918962584 -0.57735026918962584];
smiData.RigidTransform(4).ID = "F[base_qube-1:-:hub_soporte_enc-2]";

%Translation Method - Cartesian
%Rotation Method - Arbitrary Axis
smiData.RigidTransform(5).translation = [0 0 0];  % mm
smiData.RigidTransform(5).angle = 0;  % rad
smiData.RigidTransform(5).axis = [0 0 0];
smiData.RigidTransform(5).ID = "B[base_qube-1:-:]";

%Translation Method - Cartesian
%Rotation Method - Arbitrary Axis
smiData.RigidTransform(6).translation = [0 0 0];  % mm
smiData.RigidTransform(6).angle = 0;  % rad
smiData.RigidTransform(6).axis = [0 0 0];
smiData.RigidTransform(6).ID = "F[base_qube-1:-:]";

%Translation Method - Cartesian
%Rotation Method - Arbitrary Axis
smiData.RigidTransform(7).translation = [25.600000000000101 21.750000000000156 -0.60000000002066489];  % mm
smiData.RigidTransform(7).angle = 1.1176217186417947e-12;  % rad
smiData.RigidTransform(7).axis = [0.96810310212453354 0.25055215755777299 0];
smiData.RigidTransform(7).ID = "AssemblyGround[hub_soporte_enc-2:Plastico_enc-1]";

%Translation Method - Cartesian
%Rotation Method - Arbitrary Axis
smiData.RigidTransform(8).translation = [-0.10000000000000829 11.399999999999993 -0.099999999999923914];  % mm
smiData.RigidTransform(8).angle = 0;  % rad
smiData.RigidTransform(8).axis = [0 0 0];
smiData.RigidTransform(8).ID = "AssemblyGround[hub_soporte_enc-2:Cilindro_enc-1]";

%Translation Method - Cartesian
%Rotation Method - Arbitrary Axis
smiData.RigidTransform(9).translation = [0 0 0];  % mm
smiData.RigidTransform(9).angle = 0;  % rad
smiData.RigidTransform(9).axis = [0 0 0];
smiData.RigidTransform(9).ID = "AssemblyGround[hub_soporte_enc-2:disco_hub-3]";

%Translation Method - Cartesian
%Rotation Method - Arbitrary Axis
smiData.RigidTransform(10).translation = [57.999999999999794 0 0];  % mm
smiData.RigidTransform(10).angle = 0.0013531073263736387;  % rad
smiData.RigidTransform(10).axis = [1 0 0];
smiData.RigidTransform(10).ID = "AssemblyGround[brazo_pendulo-4:pendulo_r-1]";

%Translation Method - Cartesian
%Rotation Method - Arbitrary Axis
smiData.RigidTransform(11).translation = [0 0 0];  % mm
smiData.RigidTransform(11).angle = 0;  % rad
smiData.RigidTransform(11).axis = [0 0 0];
smiData.RigidTransform(11).ID = "AssemblyGround[brazo_pendulo-4:brazo-1]";


%============= Solid =============%
%Center of Mass (CoM) %Moments of Inertia (MoI) %Product of Inertia (PoI)

%Initialize the Solid structure array by filling in null values.
smiData.Solid(6).mass = 0.0;
smiData.Solid(6).CoM = [0.0 0.0 0.0];
smiData.Solid(6).MoI = [0.0 0.0 0.0];
smiData.Solid(6).PoI = [0.0 0.0 0.0];
smiData.Solid(6).color = [0.0 0.0 0.0];
smiData.Solid(6).opacity = 0.0;
smiData.Solid(6).ID = "";

%Inertia Type - Custom
%Visual Properties - Simple
smiData.Solid(1).mass = 1.1394000000000002;  % kg
smiData.Solid(1).CoM = [2.3712695958723552e-05 50.81899437254507 -0.0079124829827644187];  % mm
smiData.Solid(1).MoI = [1969.0478445170602 1975.2405134392691 1968.9117047885213];  % kg*mm^2
smiData.Solid(1).PoI = [0.49851912559494099 0.0007006547435137691 -0.0016241960225148514];  % kg*mm^2
smiData.Solid(1).color = [0.8666666666666667 0.90980392156862744 1];
smiData.Solid(1).opacity = 1;
smiData.Solid(1).ID = "base_qube*:*Predeterminado";

%Inertia Type - Custom
%Visual Properties - Simple
smiData.Solid(2).mass = 0.0050000000000000001;  % kg
smiData.Solid(2).CoM = [-0.4633485422497361 0 0.60000000000024545];  % mm
smiData.Solid(2).MoI = [0.51723211090866783 0.32626361266958759 0.32626361266958742];  % kg*mm^2
smiData.Solid(2).PoI = [0 0 0];  % kg*mm^2
smiData.Solid(2).color = [1 1 1];
smiData.Solid(2).opacity = 1;
smiData.Solid(2).ID = "Plastico_enc*:*Predeterminado";

%Inertia Type - Custom
%Visual Properties - Simple
smiData.Solid(3).mass = 0.059000000000000004;  % kg
smiData.Solid(3).CoM = [0.79889041836632513 11.031384335648129 0.099999999999361655];  % mm
smiData.Solid(3).MoI = [5.4484140974130035 9.8552080862983704 9.4219733031571931];  % kg*mm^2
smiData.Solid(3).PoI = [0 0 0.028096566021152722];  % kg*mm^2
smiData.Solid(3).color = [0.8666666666666667 0.90980392156862744 1];
smiData.Solid(3).opacity = 1;
smiData.Solid(3).ID = "Cilindro_enc*:*Predeterminado";

%Inertia Type - Custom
%Visual Properties - Simple
smiData.Solid(4).mass = 0.0106;  % kg
smiData.Solid(4).CoM = [5.531009431435713e-06 107.51946629640555 5.5239784457908446e-06];  % mm
smiData.Solid(4).MoI = [0.37860520808395465 0.62042306394581948 0.37860520862878905];  % kg*mm^2
smiData.Solid(4).PoI = [-2.3932262799000592e-07 -2.1416389378377851e-07 -2.3962724067437071e-07];  % kg*mm^2
smiData.Solid(4).color = [0.8666666666666667 0.90980392156862744 1];
smiData.Solid(4).opacity = 1;
smiData.Solid(4).ID = "disco_hub*:*Predeterminado";

%Inertia Type - Custom
%Visual Properties - Simple
% smiData.Solid(5).mass = 0.024;  % kg
% smiData.Solid(5).CoM = [-5.6102955110515706e-06 57.903111160783722 1.3501146081847211e-05];  % mm
% smiData.Solid(5).MoI = [31.701284715889599 0.27235491912989901 31.697908977652126];  % kg*mm^2
% smiData.Solid(5).PoI = [1.4880544249452976e-05 1.1519840449742737e-06 -5.4362841943157078e-06];  % kg*mm^2
% smiData.Solid(5).color = [0.71764705882352942 0.035294117647058823 0];
% smiData.Solid(5).opacity = 1;
% smiData.Solid(5).ID = "pendulo_r*:*Predeterminado";
smiData.Solid(5).mass = 0.024;  % kg
smiData.Solid(5).CoM = [-5.6102955110515706e-06 57.911160783720312 1.3501146081847211e-05];  % mm
smiData.Solid(5).MoI = [31.701284715889599 0.27235491912989901 31.697908977652126];  % kg*mm^2
smiData.Solid(5).PoI = [1.4880544249452976e-05 1.1519840449742737e-06 -5.4362841943157078e-06];  % kg*mm^2
smiData.Solid(5).color = [0.71764705882352942 0.035294117647058823 0];
smiData.Solid(5).opacity = 1;
smiData.Solid(5).ID = "pendulo_r*:*Predeterminado";

%Inertia Type - Custom
%Visual Properties - Simple
smiData.Solid(6).mass = 0.035000000000000004;  % kg
smiData.Solid(6).CoM = [30.688101306569884 0 0];  % mm
smiData.Solid(6).MoI = [0.19621479196098537 12.664927363780716 12.664927363780716];  % kg*mm^2
smiData.Solid(6).PoI = [0 0 0];  % kg*mm^2
smiData.Solid(6).color = [0.7803921568627451 0.7803921568627451 0.7803921568627451];
smiData.Solid(6).opacity = 1;
smiData.Solid(6).ID = "brazo*:*Predeterminado";


%============= Joint =============%
%X Revolute Primitive (Rx) %Y Revolute Primitive (Ry) %Z Revolute Primitive (Rz)
%X Prismatic Primitive (Px) %Y Prismatic Primitive (Py) %Z Prismatic Primitive (Pz) %Spherical Primitive (S)
%Constant Velocity Primitive (CV) %Lead Screw Primitive (LS)
%Position Target (Pos)

%Initialize the RevoluteJoint structure array by filling in null values.
smiData.RevoluteJoint(2).Rz.Pos = 0.0;
smiData.RevoluteJoint(2).ID = "";

smiData.RevoluteJoint(1).Rz.Pos = 179.94807011133292;  % deg
smiData.RevoluteJoint(1).ID = "[hub_soporte_enc-2:-:brazo_pendulo-4]";

smiData.RevoluteJoint(2).Rz.Pos = -89.999999999999375;  % deg
smiData.RevoluteJoint(2).ID = "[base_qube-1:-:hub_soporte_enc-2]";

