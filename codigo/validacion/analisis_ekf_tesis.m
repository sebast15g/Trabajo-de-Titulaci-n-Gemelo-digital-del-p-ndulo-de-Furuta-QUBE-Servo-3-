function analisis_ekf_tesis()
% ANALISIS_EKF_TESIS  Verificacion del observador (EKF, la "sombra" del gemelo)
%   sobre las 10 corridas reales de E1, E2 y E3. Corre el EKF offline (mismo
%   nucleo que ekf_step.m) sobre las mediciones (theta, alpha, Vm) y evalua:
%     - innovacion nu = medida - prediccion del modelo (un paso adelante) en theta y alpha
%     - seguimiento del estado (theta_hat, alpha_hat vs medido)
%     - consistencia NIS = nu' S^-1 nu (banda chi2 de 2 g.l.)
%     - perturbacion del cable d_hat y velocidades estimadas
%   Agrega sobre las 10 corridas con IC de la media (t_9 = 2.262).
%   Cruza el NIS offline de E3 contra el NIS registrado en linea (validacion).
%   Genera figs/resultados/{EKF_estados,EKF_nis,EKF_innov}.png y EKF_metrics.mat.
%   Requiere en el path: furuta_f_aug, furuta_Fc, furuta_meas, furuta_Hjac.

    here=fileparts(mfilename('fullpath')); if ~isempty(here), cd(here); end
    if ~exist('figs/resultados','dir'), mkdir('figs/resultados'); end
    Ts=0.002; tt=2.262; nrun=10;
    lo=0.0506; hi=7.3778;                 % banda chi2(2) al 95% por muestra
    exps={'E1','E2','E3'};
    R=struct();
    fprintf('\n== EKF sobre 10 corridas x 3 experimentos ==\n');
    for e=1:3
        ex=exps{e}; files=runfiles(ex);
        innTh=zeros(1,nrun); innAl=zeros(1,nrun); trkTh=zeros(1,nrun); trkAl=zeros(1,nrun);
        nis=zeros(1,nrun); nisfrac=zeros(1,nrun); dvAl=zeros(1,nrun);
        traces=cell(1,nrun);
        for i=1:nrun
            [t,th,al,Vm,ON]=loadrun(ex,files{i},Ts);
            w=metricwin(ex,al,t,Ts);
            if strcmp(ex,'E3')
                % E3: el EKF corrio EN LINEA dentro del lazo; se usan sus registros
                Xh=[ON.xh; ON.dhat]; NIS=ON.nis; INN=[th-ON.xh(1,:); wrapf(al)-wrapf(ON.xh(2,:))];
                innTh(i)=NaN; innAl(i)=NaN; trkTh(i)=NaN; trkAl(i)=NaN;
            else
                [Xh,NIS,INN]=run_ekf(th,al,Vm,Ts);
                innTh(i)=d2(rmsf(INN(1,w))); innAl(i)=d2(rmsf(INN(2,w)));
                trkTh(i)=d2(rmsf(Xh(1,w)-th(w))); trkAl(i)=d2(rmsf(Xh(2,w)-al(w)));
            end
            nis(i)=mean(NIS(w),'omitnan'); nisfrac(i)=100*mean(NIS(w)>=lo & NIS(w)<=hi);
            dal=gradient(al,Ts); dvAl(i)=rmsf(Xh(4,w)-dal(w));
            traces{i}=struct('t',t,'th',th,'al',al,'Xh',Xh,'NIS',NIS,'INN',INN,'Vm',Vm,'w',w);
        end
        M=struct('innTh',innTh,'innAl',innAl,'trkTh',trkTh,'trkAl',trkAl,...
                 'nis',nis,'nisfrac',nisfrac,'dvAl',dvAl);
        R.(ex).M=M; R.(ex).traces=traces;
        fprintf(['%s | innTheta=%.3f+-%.3f  innAlpha=%.3f+-%.3f deg | '...
                 'trkTheta=%.3f  trkAlpha=%.3f deg | NIS=%.2f+-%.2f  in-banda=%.0f%%\n'],...
            ex, mean(innTh),ci(innTh,tt), mean(innAl),ci(innAl,tt),...
            mean(trkTh),mean(trkAl), mean(nis),ci(nis,tt), mean(nisfrac));
    end
    save('EKF_metrics.mat','R');
    make_figs(R);
    fprintf('\n== analisis_ekf_tesis: OK ==\n');
end

% ------------------------------------------------------------------ EKF
function [Xh,NIS,INN]=run_ekf(th,al,Vm,Ts)
    N=numel(th); Q=diag([1e-7 1e-7 1e-5 1e-5 1e-4]); Rm=diag([7.84e-7 7.84e-7]);
    xa=[th(1);al(1);(th(2)-th(1))/Ts;(al(2)-al(1))/Ts;0]; P=diag([0.02 0.02 1 1 1e-6]);
    Xh=zeros(5,N); NIS=zeros(1,N); INN=zeros(2,N);
    for k=1:N
        u=Vm(k);
        F=eye(5)+Ts*furuta_Fc(xa,u); xp=xa+Ts*furuta_f_aug(xa,u); Pp=F*P*F'+Q;
        H=furuta_Hjac(xp,u); yh=furuta_meas(xp,u); nu=[th(k);al(k)]-yh; Sk=H*Pp*H'+Rm;
        Kk=Pp*H'/Sk; xa=xp+Kk*nu; P=(eye(5)-Kk*H)*Pp;
        Xh(:,k)=xa; NIS(k)=nu'/Sk*nu; INN(:,k)=nu;
    end
end

% ------------------------------------------------------------------ datos
function [t,th,al,Vm,ON]=loadrun(ex,f,Ts)
    D=gv(f); ON=[];
    switch ex
        case {'E1','E2'}                       % t=1 th=4 al=5(continua) Vm=6
            t=D(1,:); th=D(4,:); al=D(5,:); Vm=D(6,:);
        case 'E3'                              % t=1 th=3 al=4(wrap) Vm=5 xhat=6:9 dhat=10 nis=11
            t=D(1,:); th=D(3,:); al=unwrap(wrapf(D(4,:))); Vm=D(5,:);
            ON=struct('xh',D(6:9,:),'dhat',D(10,:),'nis',D(11,:));
    end
    if numel(t)<2 || all(t==0), t=(0:size(D,2)-1)*Ts; end
end

function w=metricwin(ex,al,t,Ts)
    N=numel(al); k0=round(0.2/Ts);
    if strcmp(ex,'E1'), k0=max(k0,release_idx(al)); end   % E1: desde la soltada
    w=k0:N;
end

% ------------------------------------------------------------------ figuras
function make_figs(R)
    ex={'E1','E2','E3'}; ttl={'Caida libre (E1)','Respuesta forzada (E2)','Lazo cerrado (E3)'};
    cM=[.15 .35 .75]; cE=[.85 .15 .15];
    % ---- FIG 1: estado estimado vs medido (corrida representativa) ----
    f=figure('Color','w','Position',[50 50 1150 820]);
    tl=tiledlayout(3,2,'Padding','compact','TileSpacing','compact');
    for e=1:3
        T=R.(ex{e}).traces{1}; t=T.t; w=T.w;
        nexttile; hold on; grid on;
        plot(t(w),d2(T.th(w)),'Color',cM,'LineWidth',1.1);
        plot(t(w),d2(T.Xh(1,w)),'--','Color',cE,'LineWidth',1.0);
        ylabel('\theta [deg]'); title([ttl{e} ' — brazo \theta']);
        if e==1, legend({'medido','EKF'},'Location','best','FontSize',8); end
        nexttile; hold on; grid on;
        if e==3      % E3 en lazo cerrado: vista envuelta (natural para el balance)
            aM=d2(wrapf(T.al(w))); aE=d2(wrapf(T.Xh(2,w)));
        else
            aM=d2(T.al(w)); aE=d2(T.Xh(2,w));
        end
        plot(t(w),aM,'Color',cM,'LineWidth',1.1);
        plot(t(w),aE,'--','Color',cE,'LineWidth',1.0);
        ylabel('\alpha [deg]'); title([ttl{e} ' — pendulo \alpha']);
    end
    xlabel(tl,'tiempo [s]');
    title(tl,'Estado estimado por el EKF frente a la medida real (una corrida)');
    exportgraphics(f,'figs/resultados/EKF_estados.png','Resolution',140); close(f);

    % ---- FIG 2: NIS en el tiempo (log) con banda chi2 ----
    f=figure('Color','w','Position',[50 50 1150 460]);
    tl=tiledlayout(1,3,'Padding','compact','TileSpacing','compact');
    for e=1:3
        T=R.(ex{e}).traces{1}; t=T.t; w=T.w;
        nexttile; hold on; grid on;
        yl=[0.02 200];
        fill([t(w(1)) t(w(end)) t(w(end)) t(w(1))],[0.0506 0.0506 7.3778 7.3778],...
             [.8 .9 .8],'EdgeColor','none','FaceAlpha',.5);
        plot(t(w),max(T.NIS(w),1e-3),'Color',[.2 .2 .2 .6],'LineWidth',.5);
        yline(2,'k--','ideal=2','LabelHorizontalAlignment','left','FontSize',7);
        set(gca,'YScale','log'); ylim(yl);
        ylabel('NIS'); xlabel('t [s]');
        title(sprintf('%s   NIS medio=%.1f', ttl{e}, mean(R.(ex{e}).M.nis)));
    end
    title(tl,'Consistencia del EKF (NIS) y banda \chi^2 del 95% (2 g.l.)');
    exportgraphics(f,'figs/resultados/EKF_nis.png','Resolution',140); close(f);

    % ---- FIG 3: innovacion RMS (barras, IC) + perturbacion d_hat ----
    f=figure('Color','w','Position',[50 50 1150 460]);
    tl=tiledlayout(1,2,'Padding','compact','TileSpacing','compact');
    tt=2.262;
    nexttile; hold on; grid on;
    mTh=zeros(1,3); eTh=zeros(1,3); mAl=zeros(1,3); eAl=zeros(1,3);
    for e=1:3
        M=R.(ex{e}).M; mTh(e)=mean(M.innTh); eTh(e)=ci(M.innTh,tt);
        mAl(e)=mean(M.innAl); eAl(e)=ci(M.innAl,tt);
    end
    bx=(1:3); wd=0.35;
    b1=bar(bx-wd/2,mTh,wd,'FaceColor',[.35 .55 .8]); b2=bar(bx+wd/2,mAl,wd,'FaceColor',[.85 .5 .3]);
    errorbar(bx-wd/2,mTh,eTh,'k','LineStyle','none','CapSize',6);
    errorbar(bx+wd/2,mAl,eAl,'k','LineStyle','none','CapSize',6);
    set(gca,'XTick',[1 2],'XTickLabel',{'E1','E2'},'XLim',[0.5 2.5]);
    ylabel('RMS de la innovacion [deg]');
    legend([b1 b2],{'\theta','\alpha'},'Location','northwest','FontSize',8);
    title('Error de prediccion del modelo (innovacion), 10 corridas');
    % velocidad estimada (estado no medido) vs diferencia finita, E1
    nexttile; hold on; grid on;
    T=R.E1.traces{1}; t=T.t; dfd=gradient(T.al,0.002);
    i0=find(t>=t(T.w(1))+2,1); i1=find(t>=t(T.w(1))+4,1); ww=i0:i1;
    plot(t(ww),dfd(ww),'Color',[.6 .6 .6],'LineWidth',.6);
    plot(t(ww),T.Xh(4,ww),'Color',[.85 .15 .15],'LineWidth',1.1);
    ylabel('$\dot{\alpha}$ [rad/s]','Interpreter','latex'); xlabel('t [s]');
    legend({'diferencia finita','EKF'},'Location','best','FontSize',8);
    title('Velocidad estimada (estado no medido), E1');
    exportgraphics(f,'figs/resultados/EKF_innov.png','Resolution',140); close(f);
end

% ------------------------------------------------------------------ utilidades
function y=wrapf(x), y=mod(x+pi,2*pi)-pi; end
function y=d2(x), y=x*180/pi; end
function y=rmsf(x), y=sqrt(mean(x.^2,'omitnan')); end
function y=ci(x,tt), y=tt*std(x,'omitnan')/sqrt(numel(x)); end
function D=gv(f), S=load(f); fn=fieldnames(S); D=S.(fn{1}); if size(D,1)>size(D,2), D=D.'; end; end
function r=runfiles(ex)
    switch ex
        case 'E1', r={'fid_E1_qhw.mat','fid_E1_qhw_2.mat','fid_E1_qhw_3.mat','fid_E1_qhw_4.mat','fid_E1_qhw_5.mat','fid_E1_qhw_6.mat','fid_E1_qhw_7.mat','fid_E1_qhw_8.mat','fid_E1_qhw_9.mat','fid_E1_qhw_10.mat'};
        case 'E2', r={'fid_E2_qhw.mat','fid_E2_qhw_2.mat','fid_E2_qhw_3.mat','fid_E2_qhw_4.mat','fid_E2_qhw_5.mat','fid_E2_qhw_6.mat','fid_E2_qhw_7.mat','fid_E2_qhw_8.mat','fid_E2_qhw_9.mat','fid_E2_qhw_10.mat'};
        case 'E3', r={'fid_E3_qhw_1.mat','fid_E3_qhw_2.mat','fid_E3_qhw_3.mat','fid_E3_qhw_4.mat','fid_E3_qhw_5.mat','fid_E3_qhw_6.mat','fid_E3_qhw_7.mat','fid_E3_qhw_8.mat','fid_E3_qhw_9.mat','fid_E3_qhw_10.mat'};
    end
end
function k0=release_idx(al)
    du=abs(wrapf(al)); ho=du<0.35; dd=diff([0 ho 0]); s=find(dd==1); e=find(dd==-1)-1;
    if isempty(s), k0=1; return; end
    [~,mi]=max(e-s); k0=e(mi); while k0<numel(al)-9 && du(k0)<0.5, k0=k0+1; end
end
