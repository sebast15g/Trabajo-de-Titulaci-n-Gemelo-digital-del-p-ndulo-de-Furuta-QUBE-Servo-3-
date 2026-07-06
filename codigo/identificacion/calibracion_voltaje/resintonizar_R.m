function R_sug = resintonizar_R(logfiles, factores)
% RESINTONIZAR_R  Re-sintoniza R del EKF contra corridas reales de BALANCEO.
%   Identifica el régimen de balanceo (modo=1 y |α̂|<15°, saltando el transitorio
%   de captura) para NO evaluar el NIS cuando el péndulo está abajo / en swing-up,
%   y barre un factor sobre R buscando el que centra el NIS (χ²,2 dof: media≈2,
%   95% en [0.05, 7.38]).
%
%   resintonizar_R                         usa todos los 'log_simscape_E53*.mat'
%   resintonizar_R({'a.mat','b.mat',...})  lista de logs de balanceo
%   resintonizar_R(files, factores)        factores a barrer (default logspace 0.5..50)
%
%   Devuelve R_sug (la R sugerida) e imprime el factor. R base = diag([7.84e-7 7.84e-7]).
%   Requiere: cargar_log_quarc, furuta_f_aug/_Fc/_meas/_Hjac.

    ddir=fullfile(repo_root,'datos','calibracion_voltaje');   % logs de balanceo (E53)
    if nargin<1 || isempty(logfiles)
        d=dir(fullfile(ddir,'log_simscape_E53*.mat')); logfiles={d.name};
    end
    if ischar(logfiles)||isstring(logfiles), logfiles=cellstr(logfiles); end
    if nargin<2 || isempty(factores), factores=[0.5 1 2 3 5 7 10 15 20 30 50]; end
    R0=diag([7.84e-7 7.84e-7]); Ts=0.002; lo=0.0506; hi=7.378;

    % --- 1) Cargar cada log y extraer el tramo de BALANCEO ---
    Yc={}; Vc={}; Mc={}; nseg=0;
    for i=1:numel(logfiles)
        fp=logfiles{i}; if ~isfile(fp), fp=fullfile(ddir,logfiles{i}); end
        D=cargar_log_quarc(fp); t=D(1,:); thm=D(2,:); xh=D(4:7,:); N=size(D,2);
        % detectar modo (binaria) y Vm (mayor rango no binario/no constante)
        ex=8:size(D,1);
        isbin=arrayfun(@(r) isequal(unique(D(r,:)),[0 1]), ex);
        iscon=arrayfun(@(r) std(D(r,:))<1e-9, ex);
        modeS=[]; if any(isbin), modeS=D(ex(find(isbin,1,'last')),:); end
        rest=ex(~isbin&~iscon); Vm=zeros(1,N);
        if numel(rest)>=2, [~,iv]=max(arrayfun(@(r) max(abs(D(r,:))), rest)); Vm=D(rest(iv),:); end
        aw=atan2(sin(xh(2,:)),cos(xh(2,:)));
        % máscara de balanceo: |α|<15° y modo=1 (si existe), saltando 1 s tras cada captura
        bal = abs(aw)<deg2rad(15);
        if ~isempty(modeS), bal = bal & (modeS>0.5); end
        dd=diff([0 bal 0]); s=find(dd==1); e=find(dd==-1)-1;
        mask=false(1,N);
        for j=1:numel(s)
            if t(e(j))-t(s(j))>=1.5      % segmento de balanceo válido
                ini=find(t>=t(s(j))+1,1); if isempty(ini),ini=s(j);end
                mask(ini:e(j))=true; nseg=nseg+1;
            end
        end
        fprintf('  %-28s : %d muestras, balanceo %.1f s\n', logfiles{i}, N, sum(mask)*Ts);
        % guardo TODO el log (para correr el EKF) + la máscara de balanceo
        Yc{end+1}=[thm; xh(2,:)]; Vc{end+1}=Vm; Mc{end+1}=mask; %#ok
    end
    fprintf('Total segmentos de balanceo: %d\n\n', nseg);

    % --- 2) Barrer factor de R ---
    medN=zeros(size(factores)); in95=zeros(size(factores));
    for q=1:numel(factores)
        allnis=[];
        for i=1:numel(Yc)
            nis=run_ekf_R(Yc{i}, Vc{i}, Ts, factores(q)*R0);
            v=nis(Mc{i}); v=v(isfinite(v)); allnis=[allnis v]; %#ok
        end
        medN(q)=median(allnis); in95(q)=100*mean(allnis>=lo & allnis<=hi);
    end

    % --- 3) Elegir factor: mediana del NIS más cercana a 2 ---
    [~,ib]=min(abs(medN-2)); f=factores(ib); R_sug=f*R0;
    fprintf('factor   NIS_mediana   %%en95\n');
    for q=1:numel(factores), fprintf('  %5.1f      %7.2f       %5.1f%s\n', factores(q),medN(q),in95(q), tern(q==ib,'   <--',''));end
    fprintf('\nSUGERIDO: factor=%.1f -> R = diag([%.3g %.3g])  (NIS mediana=%.2f, %%en95=%.1f%%)\n', f, R_sug(1,1),R_sug(2,2), medN(ib), in95(ib));
    fprintf('Pon en ekf_step.m:  R = diag([%.4g %.4g]);\n', R_sug(1,1), R_sug(2,2));

    figure('Name','Re-sintonía de R','Color','w','Position',[80 80 900 420]);
    yyaxis left; semilogx(factores,medN,'-o'); ylabel('NIS mediana'); hold on; yline(2,'k--');
    yyaxis right; semilogx(factores,in95,'-s'); ylabel('% en banda 95%'); yline(95,'k:');
    xlabel('factor sobre R'); grid on; title('NIS vs factor de R (objetivo: mediana 2, %en95 ~95)');
    xline(f,'g-',sprintf('f=%.1f',f));
end

function s=tern(c,a,b), if c,s=a;else,s=b;end, end
function nis = run_ekf_R(Y, Vmseq, Ts, R)
    Q=diag([1e-7 1e-7 1e-5 1e-5 1e-4]);
    N=size(Y,2); xa=[Y(1,1);Y(2,1);0;0;0]; P=diag([0.02 0.02 1 1 1e-6]); I=eye(5); nis=nan(1,N);
    for k=1:N
        u=Vmseq(k); y=Y(:,k);
        F=I+Ts*furuta_Fc(xa,u); xp=xa+Ts*furuta_f_aug(xa,u); Pp=F*P*F.'+Q;
        H=furuta_Hjac(xp,u); yh=furuta_meas(xp,u); Sk=H*Pp*H.'+R;
        if ~all(isfinite(xp)) || rcond(Sk)<1e-14, return; end
        innov=y-yh; nis(k)=innov.'*(Sk\innov); Kk=Pp*H.'/Sk; xa=xp+Kk*innov; P=(I-Kk*H)*Pp;
    end
end
