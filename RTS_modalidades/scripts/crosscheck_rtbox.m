% CROSSCHECK_RTBOX  Comparativa de fidelidad de las 4 modalidades (RTB/QSM/QHW/SIM)
% contra la planta real M0 (=QHW). Verifica que la box corregida (tiempo=seq x2ms,
% E2 con RATIO=1) reproduce las mismas metricas que QSM y el real -> misma M1.
%
% Layouts (fila = canal):
%   RTB E1/E2 (8):  [seq, th, al, dth, dal, thm, alm, Vm]                 t=seq*2e-3
%   QSM/SIM E1/E2 (9): [t, seq, th, al, dth, dal, thm, alm, Vm]
%   QHW E1/E2 (6):  [t, seq, tmod, th, al, Vm]
%   RTB E3 (16): [seq, th, al, dth,dal, thm,alm, Vm, thh,alh,dthh,dalh, dh, nis, mode, E]
%   QSM E3 (18): [t, seq, th, al, dth,dal, thm,alm, Vm, thh,alh,dthh,dalh, dh, nis, mode, E, thref]
%   QHW E3 (14): [t, seq, tmod, th, al, Vm, thh,alh,dthh,dalh, dh, nis, mode, E]

% logs resueltos por el path (setup_paths anade RTS_modalidades/<modalidad>)

% ---------------- E1: f_n / zeta (caida libre) ----------------
fprintf('\n================ E1  (caida libre)  fidelidad ================\n');
fprintf('%-6s %8s %8s %10s\n','mod','f_n[Hz]','zeta','nota');
[t,al] = load_open('fid_E1_rtbox.mat','RTB');
[fn,ze]=fnz(t,al);            fprintf('%-6s %8.3f %8.4f   %s\n','RTB',fn,ze,'seq x2ms');
[t,al] = load_open('fid_E1_qsm.mat','QSM');
[fn,ze]=fnz(t,al);            fprintf('%-6s %8.3f %8.4f\n','QSM',fn,ze);
[t,al] = load_open('fid_E1_sim.mat','SIM');
[fn,ze]=fnz(t,al);            fprintf('%-6s %8.3f %8.4f\n','SIM',fn,ze);
[t,al] = load_open('fid_E1_qhw.mat','QHW');
[tc,alc]=crop_release(t,al);  [fn,ze]=fnz(tc,alc);
fprintf('%-6s %8.3f %8.4f   %s\n','QHW(M0)',fn,ze,'recortado tras soltada');

% ---------------- E2: rangos theta/alpha (respuesta forzada) ----------------
fprintf('\n================ E2  (respuesta forzada)  rangos ================\n');
fprintf('%-6s %14s %16s %8s\n','mod','theta[min,max]','alpha[min,max]','Vm_max');
mods = {'RTB','fid_E2_rtbox.mat';
        'QSM','fid_E2_qsm.mat';
        'QHW','fid_E2_qhw.mat'};
for i=1:size(mods,1)
  [~,al,th,Vm] = load_open(mods{i,2}, mods{i,1});
  fprintf('%-6s [%6.1f,%6.1f] [%6.1f,%6.1f] %8.2f\n', mods{i,1}, ...
     min(th)*180/pi,max(th)*180/pi, min(al)*180/pi,max(al)*180/pi, max(abs(Vm)));
end

% ---------------- E3: desempeno del lazo cerrado ----------------
fprintf('\n================ E3  (lazo cerrado)  desempeno ================\n');
fprintf('%-6s %9s %8s %10s %10s %7s\n','mod','t_catch','bal%','a_std[deg]','th_std[deg]','NIS');
E3 = {'RTB','fid_E3_rtbox.mat';
      'QSM','fid_E3_qsm.mat';
      'QHW','fid_E3_qhw.mat'};
for i=1:size(E3,1)
  [tc,bal,alstd,thstd,nism] = load_closed(E3{i,2}, E3{i,1});
  fprintf('%-6s %9.3f %8.1f %10.2f %10.2f %7.2f\n', E3{i,1}, tc, bal, alstd, thstd, nism);
end
fprintf('\n(QHW = planta real M0. RTB/QSM/SIM usan la MISMA M1 -> deben coincidir entre si\n');
fprintf(' y aproximar a QHW dentro de la brecha de fidelidad M1 vs M0.)\n');

% ================= helpers =================
function [t,al,th,Vm] = load_open(fp, mod)
  S=load(fp); fn=fieldnames(S); M=S.(fn{1}); if size(M,1)>size(M,2), M=M.'; end
  switch mod
    case 'RTB'
      seq=M(1,:); t=(seq-seq(1))*2e-3; th=M(2,:); al=M(3,:); Vm=M(8,:);
    case {'QSM','SIM'}
      t=M(1,:); th=M(3,:); al=M(4,:); Vm=M(9,:);
    case 'QHW'
      t=M(1,:); th=M(4,:); al=M(5,:); Vm=M(6,:);
  end
  t=t(:).'; al=al(:).'; th=th(:).'; Vm=Vm(:).';
end
function [tc,bal,alstd,thstd,nism] = load_closed(fp, mod)
  % Usa alpha_HAT del EKF (centrada en 0=arriba en TODAS las modalidades) para la
  % std de balance, y el canal mode (binario) correcto de cada layout.
  %   RTB(16): th=2  alhat=10 mode=15 nis=14   t=seq*2e-3
  %   QSM(18): th=3  alhat=11 mode=16 nis=15   t=fila1
  %   QHW(14): th=3  alhat= 7 mode=12 nis=11   t=fila1  (mode=12 binario; fila13=E)
  S=load(fp); fn=fieldnames(S); M=S.(fn{1}); if size(M,1)>size(M,2), M=M.'; end
  switch mod
    case 'RTB', seq=M(1,:); t=(seq-seq(1))*2e-3; th=M(2,:); al=M(10,:); nis=M(14,:); mode=M(15,:);
    case 'QSM', t=M(1,:); th=M(3,:); al=M(11,:); nis=M(15,:); mode=M(16,:);
    case 'QHW', t=M(1,:); th=M(3,:); al=M(7,:);  nis=M(11,:); mode=M(12,:);
  end
  t=t(:).'; b=mode>0.5; ic=find(b,1,'first');
  tc = t(ic); bal=100*mean(b);
  alw = atan2(sin(al),cos(al));            % alpha_hat envuelta, 0=arriba
  alstd = std(alw(b))*180/pi; thstd = std(th(b)-mean(th(b)))*180/pi; nism = mean(nis(b));
end
function [fn,ze]=fnz(t,a)
  fn=NaN; ze=0; a=a(:).'; t=t(:).'; n=numel(a);
  s=a-mean(a(max(1,n-round(0.1*n)):end));
  amp=max(abs(s(1:min(n,round(0.3*n))))); if amp<=0, return; end
  h=0.15*amp; zc=[]; armed=false;
  for i=1:n
    if s(i)<-h, armed=true; end
    if armed && s(i)>0, zc(end+1)=i; armed=false; end %#ok<AGROW>
  end
  if numel(zc)<3, return; end
  fn=1/median(diff(t(zc)));
  Ts=median(diff(t)); minsep=max(1,round(0.6/fn/Ts)); last=-inf; pk=[];
  for i=2:numel(s)-1, if s(i)>s(i-1)&&s(i)>=s(i+1)&&s(i)>0&&(i-last)>=minsep, pk(end+1)=s(i); last=i; end; end %#ok<AGROW>
  if numel(pk)>=2, r=pk(1:end-1)./pk(2:end); r=r(r>0&isfinite(r)); d=median(log(r)); ze=d/sqrt(4*pi^2+d^2); end
end
function [tc,ac]=crop_release(t,a)
  % recorta el tramo manual de levantar el pendulo (QHW): desde la mayor excursion
  ar=mean(a(max(1,end-round(0.1*numel(a))):end)); [~,im]=max(abs(a-ar));
  tc=t(im:end)-t(im); ac=a(im:end);
end
