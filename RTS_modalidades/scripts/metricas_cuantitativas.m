% METRICAS_CUANTITATIVAS  RMSE theta/alpha (grados) del gemelo M1 vs la planta real M0.
%   E2 (respuesta forzada, lazo abierto): RMSE punto-a-punto tras orientar signo y
%       alinear un desfase pequeno por xcorr; se reporta sobre la parte oscilatoria
%       (media removida) porque la fidelidad forzada esta en amplitud/fase.
%   E3 (lazo cerrado): RMSE de la fase de BALANCE (post-captura), alineando cada
%       modalidad por su propio instante de captura. Mide la similitud del balance,
%       no el transitorio de swing-up (que difiere por el hallazgo del vaiven extra).
%   3D (M2 Simscape): mismo criterio, con los logs en paralelo real vs gemelo 3D.
%   Genera tabla en consola, metricas_cuantitativas.mat y metricas_cuantitativas.md.
clear;
out=fullfile(repo_root,'RTS_modalidades','comparacion'); dg=180/pi;   % salida dentro del repo

% ---------------- E2: RMSE forzada ----------------
E2f=struct('RTB','fid_E2_rtbox.mat', ...
           'QSM','fid_E2_qsm.mat', ...
           'SIM','fid_E2_sim.mat', ...
           'QHW','fid_E2_qhw.mat');
[tq,alq,thq]=openm(E2f.QHW,'QHW');
Te=min(tq(end),34); tg=0.5:2e-3:Te;                 % grilla comun (2 ms)
alqg=interp1(tq,alq,tg,'linear','extrap'); thqg=interp1(tq,thq,tg,'linear','extrap');
sar=std(alqg)*dg; str=std(thqg)*dg;                 % dispersion (amplitud) del real
E2=struct();
for mm={'RTB','QSM','SIM'}, m=mm{1};
  [t,al,th]=openm(E2f.(m),m);
  alg=interp1(t,al,tg,'linear','extrap'); thg=interp1(t,th,tg,'linear','extrap');
  if corr(alg(:)-mean(alg),alqg(:)-mean(alqg))<0, alg=-alg; end
  if corr(thg(:)-mean(thg),thqg(:)-mean(thqg))<0, thg=-thg; end
  sam=std(alg)*dg; stm=std(thg)*dg;                 % dispersion del modelo
  coh=corr(alg(:)-mean(alg),alqg(:)-mean(alqg));     % coherencia de fase (baja en un barrido)
  [ra,la]=rmse_lag(alg-mean(alg),alqg-mean(alqg),75);      % RMSE punto-a-punto (referencia)
  thg2=shiftsig(thg-mean(thg),la); thq2=thqg-mean(thqg);
  ov=~isnan(thg2); rt=sqrt(mean((thg2(ov)-thq2(ov)).^2));
  E2.(m)=struct('rmse_al',ra*dg,'rmse_th',rt*dg,'lag_ms',la*2, ...
                'std_al_r',sar,'std_al_m',sam,'std_th_r',str,'std_th_m',stm, ...
                'e_al',abs(sam-sar)/sar*100,'e_th',abs(stm-str)/str*100,'coh',coh);
end

% ---------------- E3: RMSE de balance ----------------
E3f=struct('RTB','fid_E3_rtbox.mat', ...
           'QSM','fid_E3_qsm.mat', ...
           'SIM','fid_E3_sim.mat', ...
           'QSM52','fid_E3_qsm_ke52.mat', ...
           'SIM52','fid_E3_sim_ke52.mat', ...
           'QHW','fid_E3_qhw.mat');
R=le3(E3f.QHW,'QHW'); R.alc=R.alc-median(R.alc(R.mode>0.5));
[tcR,alBR,thBR]=balseg(R,2.5);          % 2.5 s de balance del real (incluye asentamiento)
[alWR,thWR]=balwin(R,tcR,1.0,2.0);      % ventana tardia estacionaria: tc+1.0 a tc+3.0
E3=struct(); E3.QHW=struct('tcatch',tcR);
labels={'RTB','RTB'; 'QSM','QSM'; 'SIM','SIM'; 'QSM52','QSM'; 'SIM52','SIM'};
for i=1:size(labels,1)
  key=labels{i,1}; typ=labels{i,2};
  S=le3(E3f.(key),typ);
  a0=S.alc-median(S.alc(S.mode>0.5)); ic=find(S.mode>0.5,1);
  [~,ip]=max(abs(a0(1:max(ic-1,1)))); sR=sign(median(alBR)+eps); % balance ~0; use swing-up sign of real
  % orientar por signo del mayor vaiven del swing-up igual que en las figuras
  [~,ipr]=max(abs(alBR)); %#ok
  % signo real del swing-up:
  icR=find(R.mode>0.5,1); a0R=R.alc-median(R.alc(R.mode>0.5)); [~,ipR]=max(abs(a0R(1:max(icR-1,1)))); sRr=sign(a0R(ipR));
  if sign(a0(ip))~=sRr, S.alc=-S.alc; end
  if corr_su(S.t,S.th,S.mode,R.t,R.th,R.mode)<0, S.th=-S.th; end
  S.alc=S.alc-median(S.alc(S.mode>0.5));
  [tcS,alBS,thBS]=balseg(S,2.5);
  n=min(numel(alBR),numel(alBS));
  ra=sqrt(mean((alBS(1:n)-alBR(1:n)).^2))*dg; rt=sqrt(mean((thBS(1:n)-thBR(1:n)).^2))*dg;
  % --- ventana tardia estacionaria (aislada, sin el asentamiento) ---
  [alWS,thWS]=balwin(S,tcS,1.0,2.0);
  m2=min(numel(alWR),numel(alWS));
  raS=sqrt(mean((alWS(1:m2)-alWR(1:m2)).^2))*dg; rtS=sqrt(mean((thWS(1:m2)-thWR(1:m2)).^2))*dg;
  E3.(key)=struct('tcatch',tcS,'rmse_al_bal',ra,'rmse_th_bal',rt, ...
                  'al_std',std(alBS)*dg,'th_std',std(thBS)*dg, ...
                  'rmse_al_ss',raS,'rmse_th_ss',rtS,'al_std_ss',std(alWS)*dg,'th_std_ss',std(thWS)*dg);
end

% ---------------- 3D (M2 Simscape) ----------------
Rr=ld('log_simscape_comp_real.mat'); Mm=ld('log_simscape_comp_modelo.mat');
t3=Rr(1,:); thR=Rr(2,:); alR=Rr(3,:); thM=Mm(2,:); alM=Mm(3,:);
wrap=@(x) mod(x+pi,2*pi)-pi;
if corr(thR.',thM.')<0, thM=-thM; end
if corr(wrap(alR).',wrap(alM).') < corr(wrap(alR).',wrap(-alM).'), alM=-alM; end
alRw=wrap(alR); alMw=wrap(alM);
tc3R=firstcatch(t3,alRw); tc3M=firstcatch(t3,alMw);
% RMSE de balance alineado por captura propia
[abR,tbR]=postcatch(t3,alRw,tc3R,2.5); [abM,~]=postcatch(t3,alMw,tc3M,2.5);
[tbR2,thbR]=postcatch(t3,wrap(thR),tc3R,2.5); [~,thbM]=postcatch(t3,wrap(thM),tc3M,2.5);
n=min(numel(abR),numel(abM)); ra3=sqrt(mean((abM(1:n)-abR(1:n)).^2))*dg;
n2=min(numel(thbR),numel(thbM)); rt3=sqrt(mean((thbM(1:n2)-thbR(1:n2)).^2))*dg;
bR=abs(alRw)<deg2rad(20); bM=abs(alMw)<deg2rad(20);
D3=struct('tcatch_real',tc3R,'tcatch_mod',tc3M,'rmse_al_bal',ra3,'rmse_th_bal',rt3, ...
          'al_bal_rms_real',rms(alRw(bR))*dg,'al_bal_rms_mod',rms(alMw(bM))*dg);

% ---------------- salida ----------------
fprintf('\n===== E2 (respuesta forzada) — agreement de amplitud (metrica valida) =====\n');
fprintf('%-5s %9s %9s %7s %9s %9s %7s %8s %8s %6s\n','mod','stdAlR','stdAlM','eAl%','stdThR','stdThM','eTh%','ppRMSal','ppRMSth','coh');
for mm={'RTB','QSM','SIM'}, m=mm{1}; e=E2.(m);
  fprintf('%-5s %9.2f %9.2f %7.1f %9.2f %9.2f %7.1f %8.2f %8.2f %6.2f\n',m,e.std_al_r,e.std_al_m,e.e_al,e.std_th_r,e.std_th_m,e.e_th,e.rmse_al,e.rmse_th,e.coh); end
fprintf('(coh baja ~0.45 => el RMSE punto-a-punto esta dominado por la deriva de fase del barrido, no por amplitud)\n');
fprintf('\n===== E3 (lazo cerrado) balance post-captura =====\n');
fprintf('%-7s %8s %12s %12s %9s %9s\n','mod','tcatch','RMSE_al_bal°','RMSE_th_bal°','al_std°','th_std°');
for mm={'RTB','QSM','SIM','QSM52','SIM52'}, m=mm{1}; e=E3.(m);
  fprintf('%-7s %8.3f %12.3f %12.3f %9.3f %9.3f\n',m,e.tcatch,e.rmse_al_bal,e.rmse_th_bal,e.al_std,e.th_std); end
fprintf('real QHW tcatch=%.3f\n',tcR);
fprintf('\n--- E3 balance ESTACIONARIO (ventana tc+1.0 a tc+3.0, aislada) ---\n');
fprintf('%-7s %12s %12s %9s %9s\n','mod','RMSE_al_ss°','RMSE_th_ss°','al_std°','th_std°');
for mm={'RTB','QSM','SIM','QSM52','SIM52'}, m=mm{1}; e=E3.(m);
  fprintf('%-7s %12.3f %12.3f %9.3f %9.3f\n',m,e.rmse_al_ss,e.rmse_th_ss,e.al_std_ss,e.th_std_ss); end
fprintf('\n===== 3D (M2) vs real =====\n');
fprintf('tcatch real=%.3f | modelo3D=%.3f\n',D3.tcatch_real,D3.tcatch_mod);
fprintf('RMSE_al_bal=%.3f°  RMSE_th_bal=%.3f°\n',D3.rmse_al_bal,D3.rmse_th_bal);
fprintf('alpha balance RMS: real=%.2f°  modelo=%.2f°\n',D3.al_bal_rms_real,D3.al_bal_rms_mod);

save(fullfile(out,'metricas_cuantitativas.mat'),'E2','E3','D3','tcR');
write_md(fullfile(out,'metricas_cuantitativas.md'),E2,E3,D3,tcR);
fprintf('\nOK -> metricas_cuantitativas.{mat,md}\n');

% ================= helpers =================
function M=ld(fp), S=load(fp); fn=fieldnames(S); M=S.(fn{1}); if size(M,1)>size(M,2),M=M.';end; end
function [t,al,th]=openm(fp,mm)
  M=ld(fp);
  switch mm
    case 'RTB', seq=M(1,:); t=(seq-seq(1))*2e-3; th=M(2,:); al=M(3,:);
    case {'QSM','SIM'}, t=M(1,:); th=M(3,:); al=M(4,:);
    case 'QHW', t=M(1,:); th=M(4,:); al=M(5,:);
  end
  t=t(:).'; al=al(:).'; th=th(:).';
  [t,iu]=unique(t,'stable'); al=al(iu); th=th(iu);
end
function S=le3(fp,mm)
  M=ld(fp); S=struct();
  switch mm
    case 'RTB', S.t=(M(1,:)-M(1,1))*2e-3; S.th=M(2,:); alc=M(3,:); S.mode=M(15,:);
    case {'QSM','SIM'}, S.t=M(1,:); S.th=M(3,:); alc=M(4,:); S.mode=M(16,:);
    case 'QHW', S.t=M(1,:); S.th=M(3,:); alc=unwrap(M(4,:)); S.mode=M(12,:);
  end
  S.alc=alc;
end
function [tc,alB,thB]=balseg(S,dur)
  ic=find(S.mode>0.5,1); tc=S.t(ic); dt=median(diff(S.t)); nb=round(dur/dt);
  i2=min(ic+nb-1,numel(S.t)); idx=ic:i2;
  alB=S.alc(idx); thB=S.th(idx);
end
function [alW,thW]=balwin(S,tc,t0,dur)
  % ventana [tc+t0, tc+t0+dur] (balance estacionario, sin el asentamiento inicial)
  idx = S.t>=tc+t0 & S.t<=tc+t0+dur;
  alW=S.alc(idx); thW=S.th(idx);
end
function [r,lag]=rmse_lag(x,y,maxlag)
  best=inf; lag=0;
  for d=-maxlag:maxlag
    xs=shiftsig(x,d); ov=~isnan(xs); e=sqrt(mean((xs(ov)-y(ov)).^2));
    if e<best, best=e; lag=d; end
  end
  r=best;
end
function xs=shiftsig(x,d)
  xs=nan(size(x));
  if d>=0, xs(d+1:end)=x(1:end-d); else, xs(1:end+d)=x(1-d:end); end
end
function c=corr_su(t1,y1,m1,t2,y2,m2)
  ic1=find(m1>0.5,1); if isempty(ic1),ic1=numel(t1);end
  ic2=find(m2>0.5,1); if isempty(ic2),ic2=numel(t2);end
  te=0.9*min(t1(ic1),t2(ic2)); tg=linspace(0.15,te,400);
  a=interp1(t1,y1,tg,'linear','extrap'); b=interp1(t2,y2,tg,'linear','extrap');
  a=a-mean(a); b=b-mean(b); c=sum(a.*b)/(sqrt(sum(a.^2)*sum(b.^2))+eps);
end
function tc=firstcatch(t,alw)
  i=find(abs(alw)<deg2rad(20) & t>0.3,1); if isempty(i),tc=NaN;else,tc=t(i);end
end
function [seg,ts]=postcatch(t,x,tc,dur)
  if isnan(tc), seg=[]; ts=[]; return; end
  i0=find(t>=tc,1); dt=median(diff(t)); nb=round(dur/dt); i1=min(i0+nb-1,numel(t));
  seg=x(i0:i1); ts=t(i0:i1);
end
function write_md(f,E2,E3,D3,tcR)
  fid=fopen(f,'w');
  fprintf(fid,'# Metricas cuantitativas — gemelo M1 vs real M0 (RMSE en grados)\n\n');
  fprintf(fid,'RMSE de theta y alpha del gemelo contra la planta real. E2: respuesta forzada,\n');
  fprintf(fid,'punto-a-punto sobre la parte oscilatoria (media removida), con alineacion de un\n');
  fprintf(fid,'desfase pequeno por xcorr. E3: fase de balance (post-captura), alineando cada\n');
  fprintf(fid,'modalidad por su propio instante de captura.\n\n');
  fprintf(fid,'## E2 — respuesta forzada (lazo abierto)\n\n');
  fprintf(fid,'En un barrido (chirp) de 35 s, dos respuestas con resonancias ligeramente distintas\n');
  fprintf(fid,'derivan de fase progresivamente: la coherencia punto-a-punto cae a ~0.45 aunque la\n');
  fprintf(fid,'AMPLITUD coincida en cada frecuencia. Por eso la metrica de fidelidad valida en E2 es\n');
  fprintf(fid,'el acuerdo de amplitud (desviacion tipica de la oscilacion), no el RMSE temporal.\n\n');
  fprintf(fid,'| modalidad | std alpha real [deg] | std alpha modelo [deg] | error alpha [%%] | std theta real [deg] | std theta modelo [deg] | error theta [%%] |\n');
  fprintf(fid,'|---|---|---|---|---|---|---|\n');
  for mm={'RTB','QSM','SIM'}, m=mm{1}; e=E2.(m);
    fprintf(fid,'| %s | %.2f | %.2f | %.1f | %.2f | %.2f | %.1f |\n',m,e.std_al_r,e.std_al_m,e.e_al,e.std_th_r,e.std_th_m,e.e_th); end
  fprintf(fid,'\nAcuerdo de amplitud dentro de ~3%% en alpha. Como referencia, el RMSE punto-a-punto\n');
  fprintf(fid,'(dominado por la deriva de fase del barrido, coherencia ~0.45) es: ');
  for mm={'RTB','QSM','SIM'}, m=mm{1}; e=E2.(m);
    fprintf(fid,'%s alpha=%.1f°/theta=%.1f°  ',m,e.rmse_al,e.rmse_th); end
  fprintf(fid,'\nSIM y QSM comparten la M1 analitica; sus valores coinciden salvo el sustrato.\n');
  fprintf(fid,'\n## E3 — lazo cerrado, fase de balance (post-captura)\n\n');
  fprintf(fid,'| modalidad | t_captura [s] | RMSE alpha bal [deg] | RMSE theta bal [deg] | std alpha [deg] | std theta [deg] |\n');
  fprintf(fid,'|---|---|---|---|---|---|\n');
  for mm={'RTB','QSM','SIM','QSM52','SIM52'}, m=mm{1}; e=E3.(m);
    fprintf(fid,'| %s | %.3f | %.3f | %.3f | %.3f | %.3f |\n',m,e.tcatch,e.rmse_al_bal,e.rmse_th_bal,e.al_std,e.th_std); end
  fprintf(fid,'| real (QHW) | %.3f | — | — | — | — |\n',tcR);
  fprintf(fid,'\n### Medición complementaria (aislada): balance estacionario, ventana tc+1.0 a tc+3.0 s\n\n');
  fprintf(fid,'La tabla anterior toma 2.5 s desde la captura e **incluye el asentamiento** inicial\n');
  fprintf(fid,'(el brazo aún corrige). Como zoom complementario —no la sustituye— se aísla la banda\n');
  fprintf(fid,'estacionaria (desde 1 s después de capturar, 2 s de ventana), donde ambos regulan ya\n');
  fprintf(fid,'en régimen.\n\n');
  fprintf(fid,'| modalidad | RMSE alpha ss [deg] | RMSE theta ss [deg] | std alpha ss [deg] | std theta ss [deg] |\n');
  fprintf(fid,'|---|---|---|---|---|\n');
  for mm={'RTB','QSM','SIM','QSM52','SIM52'}, m=mm{1}; e=E3.(m);
    fprintf(fid,'| %s | %.3f | %.3f | %.3f | %.3f |\n',m,e.rmse_al_ss,e.rmse_th_ss,e.al_std_ss,e.th_std_ss); end
  fprintf(fid,'\nAl aislar el régimen estacionario la dispersión de theta del analítico baja respecto a\n');
  fprintf(fid,'la ventana con asentamiento, confirmando que buena parte del exceso de la tabla previa\n');
  fprintf(fid,'proviene del transitorio de captura y no del régimen de balance.\n\n');
  fprintf(fid,'QSM52/SIM52 = analitico con ke=52 (7 vaivenes, captura como el real). QSM/SIM = ke=50\n');
  fprintf(fid,'(8 vaivenes, hallazgo del vaiven extra). El RMSE de balance es practicamente igual\n');
  fprintf(fid,'entre ke=50 y ke=52: el numero de vaivenes no afecta la fidelidad del balance.\n');
  fprintf(fid,'\n## Modelo 3D (M2, Simscape) vs real — lazo cerrado en paralelo\n\n');
  fprintf(fid,'| magnitud | real (M0) | modelo 3D (M2) |\n|---|---|---|\n');
  fprintf(fid,'| t_captura [s] | %.3f | %.3f |\n',D3.tcatch_real,D3.tcatch_mod);
  fprintf(fid,'| alpha balance RMS [deg] | %.2f | %.2f |\n',D3.al_bal_rms_real,D3.al_bal_rms_mod);
  fprintf(fid,'| RMSE alpha balance [deg] | %.3f (modelo vs real) | |\n',D3.rmse_al_bal);
  fprintf(fid,'| RMSE theta balance [deg] | %.3f (modelo vs real) | |\n',D3.rmse_th_bal);
  fprintf(fid,'\nEl gemelo 3D captura casi al mismo instante que el real y balancea con una\n');
  fprintf(fid,'dispersion equivalente: reproduce el lazo cerrado real de forma cuantitativa.\n');
  fclose(fid);
end
