% FIGURAS_3D_E1E2  Complementario: E1 (caida libre) y E2 (forzado) del modelo 3D (M2).
% E1: decaimiento del 3D (f_n=1.83 Hz, ~ real 1.82). E2: 3D vs real (misma excitacion).
% Muestra que en lazo abierto el 3D no aporta fidelidad extra sobre el analitico.
clear;
out=fullfile(repo_root,'RTS_modalidades','comparacion'); dg=180/pi;   % figuras de salida dentro del repo
ld=@(f) getfield(load(f),char(fieldnames(load(f))));

D1=ld('E1_model3D.mat'); if size(D1,1)>size(D1,2),D1=D1.';end
D2=ld('E2_model3D.mat'); if size(D2,1)>size(D2,2),D2=D2.';end
t1=D1(1,:); a1=D1(3,:); t2=D2(1,:); a2=D2(3,:);
Rq2=ld('fid_E2_qhw.mat'); if size(Rq2,1)>size(Rq2,2),Rq2=Rq2.';end
tr2=Rq2(1,:); ar2=Rq2(5,:);

% ===== E1: 3D solo, desviacion del colgado, alineado en la soltada =====
d3 = a1 - median(a1(end-500:end));
i3 = find(abs(d3-d3(1))>0.3,1); if isempty(i3),i3=1;end
t3c = t1(i3:end)-t1(i3); d3c = d3(i3:end);

% ===== E2: 3D vs real, desviacion de la media, signo homogeneizado =====
a2d = a2-median(a2(t2>0.5));
ar2d = unwrap(ar2)-median(unwrap(ar2(tr2>0.5)));
gg=linspace(1,30,600);
if corr(interp1(t2,a2d,gg).',interp1(tr2,ar2d,gg).')<0, a2d=-a2d; end

f=figure('Color','w','Position',[60 50 1000 720]); tl=tiledlayout(f,2,1,'Padding','compact');
ax=nexttile(tl); hold(ax,'on'); grid(ax,'on');
plot(ax,t3c,d3c*dg,'Color',[0.85 0.35 0],'LineWidth',1.6);
yl=yline(ax,0,':k'); yl.Annotation.LegendInformation.IconDisplayStyle='off';
xlim(ax,[0 6]); ylabel(ax,'\alpha (desv. del colgado) [deg]');
legend(ax,{'modelo 3D (M2)'},'Location','northeast');
title(ax,'E1 — caída libre del modelo 3D (f_n = 1.83 Hz, \approx real 1.82 Hz)');
ax=nexttile(tl); hold(ax,'on'); grid(ax,'on');
plot(ax,tr2,ar2d*dg,'Color',[0 0.2 0.9],'LineWidth',1.2);
plot(ax,t2,a2d*dg,'Color',[0.85 0.35 0],'LineStyle','--','LineWidth',1.0);
xlim(ax,[0 35]); ylabel(ax,'\alpha (desv.) [deg]'); xlabel(ax,'t [s]');
legend(ax,{'real (QHW, M0)','modelo 3D (M2)'},'Location','northeast');
title(ax,'E2 — respuesta forzada: modelo 3D vs real');
exportgraphics(f,fullfile(out,'comp_3d_E1E2_vsreal.png'),'Resolution',140); close(f);
fprintf('OK -> comp_3d_E1E2_vsreal.png\n');