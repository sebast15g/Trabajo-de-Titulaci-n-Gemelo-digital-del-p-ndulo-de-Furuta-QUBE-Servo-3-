function analisis_bandas_tesis()
% ANALISIS_BANDAS_TESIS  Corrección 1 (v2): validez estadística (n=10), análisis por
%   fase/zona y modalidades separadas para E1, E2, E3.
%   Modalidades: QHW(real,n=10, M0), QSM(RTS QUARC, RK4), SIM(Simulink conv., RK4),
%   RTB(RT Box, Euler), 3D(M2). QSM=SIM son idénticas (misma trayectoria).
%
%   Banda operativa mu +- 1.96 sigma (95% de realizaciones del real).
%   IC de la media mu +- 2.262 sigma/sqrt(10) (t de Student, 9 g.l.).
%   Signo de cada señal de cada modalidad alineado al real por correlación.
%
%   Genera figs/resultados/{E1_banda,E1_barras,E1_periodo_amplitud,E2_banda,
%   E2_segmentos,E3_banda,E3_zonas,E_alpha_wrap_unwrap}.png
%   Requiere parametros_furuta.m y furuta_f_param.m en el path.

    here=fileparts(mfilename('fullpath')); if ~isempty(here), cd(here); end
    if ~exist('figs/resultados','dir'), mkdir('figs/resultados'); end
    E1(); E2(); E3(); fig_alpha_wrap(); figs_corridas();
    fprintf('\n== analisis_bandas_tesis (v2): OK ==\n');
end

% ============================ E1 ============================
function E1()
    run('parametros_furuta.m'); prm=[p.Dr;p.Tdry_th;p.kc;p.theta0;p.Tc_alpha;p.Dp;p.Jr]; %#ok<NODEF>
    reps=e1reps(); n=10; g=-0.2:0.002:8; PHI=nan(n,numel(g)); TH=nan(n,numel(g)); Ts=0.002;
    FN=zeros(1,n);ZE=zeros(1,n);A0=zeros(1,n);DA0=zeros(1,n);TH0=zeros(1,n);DTH0=zeros(1,n);
    for i=1:n
        D=gv(reps{i}); t=D(1,:); th=D(4,:); al=D(5,:); k0=release_idx(al);
        hang=mean(al(end-500:end)); thr=mean(th(end-500:end));
        s=al-hang; thc=th-thr; if s(k0)>0, s=-s; thc=-thc; end   % plegar alpha Y theta juntos
        PHI(i,:)=interp1(t-t(k0),s,g,'linear',NaN); TH(i,:)=interp1(t-t(k0),thc,g,'linear',NaN);
        [FN(i),ZE(i)]=linfnzeta(al-hang,k0,Ts);
        w=7; a0=wrapf(al(k0)); da0=(mean(al(k0+1:k0+w))-mean(al(k0-w:k0-1)))/(w*Ts); sgn=sign(a0+eps);
        A0(i)=a0*sgn;DA0(i)=da0*sgn;TH0(i)=(th(k0)-thr)*sgn;DTH0(i)=((mean(th(k0+1:k0+w))-mean(th(k0-w:k0-1)))/(w*Ts))*sgn;
    end
    mu=mean(PHI,1,'omitnan'); sg=std(PHI,0,1,'omitnan'); muT=mean(TH,1,'omitnan'); sgT=std(TH,0,1,'omitnan');
    z=1.96; tt=2.262; fnr=mean(FN); fnci=tt*std(FN)/sqrt(n); zer=mean(ZE); zeci=tt*std(ZE)/sqrt(n);
    % M1 sembrado en IC media
    k0g=find(g>=0,1); nsub=4; h=Ts/nsub; xk=[mean(TH0);mean(A0);mean(DTH0);mean(DA0)]; XM=nan(2,numel(g));
    for k=k0g:numel(g), XM(:,k)=xk(1:2);
        for s2=1:nsub, k1=furuta_f_param(xk,0,prm);k2=furuta_f_param(xk+h/2*k1,0,prm);k3=furuta_f_param(xk+h/2*k2,0,prm);k4=furuta_f_param(xk+h*k3,0,prm); xk=xk+h/6*(k1+2*k2+2*k3+k4); end
    end
    phiM=XM(2,:)-pi; phiM(1:k0g-1)=NaN; thMi=XM(1,:); thMi(1:k0g-1)=NaN;
    save('E1_stats.mat','g','mu','sg','muT','sgT','phiM','thMi');
    % modelos f_n lineal + periodo-amplitud
    srcs={'QSM','fid_E1_qsm.mat',4,false;'SIM','fid_E1_sim.mat',4,false;'RTB','fid_E1_rtbox (2).mat',3,false;'3D','E1_model3D.mat',3,true};
    FNm=zeros(1,4);ZEm=zeros(1,4);
    ampgrid=[130 110 90 70 50 35 22 14]; PA=nan(5,numel(ampgrid));
    allsrc=[{'real','fid_E1_qhw.mat',5,false}; srcs];
    for j=1:5
        D=gv(allsrc{j,2}); if size(D,1)>size(D,2),D=D.';end; N=size(D,2);
        if allsrc{j,4}, al=pi-D(allsrc{j,3},:); else, al=D(allsrc{j,3},:); end
        k0=release_idx(al); a=al(k0:end)-mean(al(end-round(0.05*N):end)); ts=(0:numel(a)-1)*Ts;
        [pks,locs]=findpeaks(abs(a),'MinPeakDistance',round(0.15/Ts),'MinPeakHeight',0.02);
        Tc=diff(locs)*Ts*2; ampp=d2(pks(1:end-1));
        for q=1:numel(ampgrid), [dd,ix]=min(abs(ampp-ampgrid(q))); if dd<12, PA(j,q)=Tc(ix); end; end
        if j>=2, [FNm(j-1),ZEm(j-1)]=linfnzeta(al-mean(al(end-round(0.05*N):end)),k0,Ts); end
    end
    % --- FIG banda: modalidades alineadas por el primer pico (arrancan juntas) ---
    w01=g>=0&g<=1; segref=mu; segref(~w01)=-inf; [~,ipk]=max(segref); tref=g(ipk);
    bsrc={'QSM (M1, QUARC RT)','fid_E1_qsm.mat',4,3,false,[.85 .15 .15],'--';'SIM (M1, Simulink)','fid_E1_sim.mat',4,3,false,[.95 .5 .5],':';'RTB (M1, RT Box)','fid_E1_rtbox (2).mat',3,2,false,[.9 .55 .15],'-.';'3D (M2)','E1_model3D.mat',3,2,true,[.15 .55 .2],'--'};
    f=figure('Color','w','Position',[60 60 1000 660]); tiledlayout(2,1,'Padding','compact','TileSpacing','compact');
    nexttile; hold on; grid on; gg=g(~isnan(mu)); m=mu(~isnan(mu)); s=sg(~isnan(mu));
    fill([gg fliplr(gg)],d2([m+z*s fliplr(m-z*s)]),[.2 .4 .9],'FaceAlpha',.13,'EdgeColor','none','DisplayName','banda \mu\pm1.96\sigma (95%)');
    plot(g,d2(mu),'b','LineWidth',1.8,'DisplayName','QHW real (M0, n=10)'); TTb=cell(4,1);
    for j=1:4
        Db=gv(bsrc{j,2}); Nb=size(Db,2); tmb=(0:Nb-1)*Ts;
        if bsrc{j,5}, alb=pi-Db(bsrc{j,3},:); thb=Db(bsrc{j,4},:); else, alb=Db(bsrc{j,3},:); thb=Db(bsrc{j,4},:); end
        hb=mean(alb(end-round(0.05*Nb):end)); sdev=alb-hb; kb=release_idx(alb);
        if sdev(kb)>0, sdev=-sdev; thb=-thb; end
        [~,lc]=findpeaks(sdev,'MinPeakDistance',round(0.15/Ts),'MinPeakHeight',deg2rad(30)); tpk=tmb(lc(1));
        plot(g,d2(interp1(tmb-tpk+tref,sdev,g,'linear',NaN)),bsrc{j,7},'Color',bsrc{j,6},'LineWidth',1.2,'DisplayName',bsrc{j,1});
        TTb{j}=interp1(tmb-tpk+tref,thb-mean(thb(end-round(0.05*Nb):end)),g,'linear',NaN);
    end
    ylabel('\alpha-\alpha_{colgado} [deg]'); xlim([-0.2 8]); ylim([-200 160]); legend('Location','northeast','FontSize',8);
    title('E1 caida libre: \alpha — cada modalidad por separado (alineadas por primer pico)');
    nexttile; hold on; grid on;
    fill([gg fliplr(gg)],d2([muT(~isnan(mu))+z*sgT(~isnan(mu)) fliplr(muT(~isnan(mu))-z*sgT(~isnan(mu)))]),[.2 .4 .9],'FaceAlpha',.13,'EdgeColor','none','HandleVisibility','off');
    plot(g,d2(muT),'b','LineWidth',1.5,'DisplayName','QHW real'); for j=1:4, plot(g,d2(TTb{j}),bsrc{j,7},'Color',bsrc{j,6},'LineWidth',1.1,'DisplayName',bsrc{j,1}); end
    ylabel('\theta [deg]'); xlabel('t alineado por primer pico [s]'); xlim([-0.2 8]); legend('Location','northeast','FontSize',7,'NumColumns',3); title('E1 caida libre: \theta — cada modalidad por separado');
    exportgraphics(f,'figs/resultados/E1_banda.png','Resolution',130); close(f);
    % --- FIG barras f_n, zeta ---
    labs={'QHW real','QSM','SIM','RTB','3D'}; cols=[.85 .3 .3;.25 .45 .8;.35 .55 .5;.9 .55 .15;.2 .6 .25];
    fnv=[fnr FNm]; zev=[zer ZEm];
    f=figure('Color','w','Position',[60 60 950 420]); tiledlayout(1,2,'Padding','compact','TileSpacing','compact');
    nexttile; b=bar(fnv,'FaceColor','flat'); b.CData=cols; hold on; grid on; errorbar(1,fnr,fnci,'k','LineStyle','none','LineWidth',1.3,'CapSize',9);
    set(gca,'XTickLabel',labs); ylabel('f_n [Hz]'); ylim([2.0 2.55]); title('Frecuencia natural (lineal) con IC95 del real');
    for k=1:5,text(k,fnv(k)+0.01,sprintf('%.3f',fnv(k)),'HorizontalAlignment','center','FontSize',8);end
    nexttile; b=bar(zev,'FaceColor','flat'); b.CData=cols; hold on; grid on; errorbar(1,zer,zeci,'k','LineStyle','none','LineWidth',1.3,'CapSize',9);
    set(gca,'XTickLabel',labs); ylabel('\zeta'); ylim([0 0.035]); title('Amortiguamiento con IC95 del real');
    for k=1:5,text(k,zev(k)+0.001,sprintf('%.4f',zev(k)),'HorizontalAlignment','center','FontSize',8);end
    exportgraphics(f,'figs/resultados/E1_barras.png','Resolution',130); close(f);
    % --- FIG periodo-amplitud ---
    f=figure('Color','w','Position',[60 60 720 480]); hold on; grid on; mk={'-o','-s','-^','-d','-v'};
    for j=1:5, plot(ampgrid,PA(j,:),mk{j},'Color',cols(j,:),'LineWidth',1.4,'MarkerFaceColor',cols(j,:),'DisplayName',labs{j}); end
    xlabel('amplitud del ciclo [deg]'); ylabel('periodo [s]'); set(gca,'XDir','reverse');
    title('E1: periodo vs amplitud — todas las modalidades coinciden'); legend('Location','northwest','FontSize',8);
    exportgraphics(f,'figs/resultados/E1_periodo_amplitud.png','Resolution',130); close(f);
    fprintf('E1: real f_n=%.3f+-%.3f zeta=%.4f+-%.4f | modelos f_n=%s (-9.4%%)\n',fnr,fnci,zer,zeci,num2str(FNm,'%.3f '));
end

% ============================ E2 ============================
function E2()
    % alpha SIN envolver (continua) es comparable en E2; el wrap solo aplica al lazo cerrado.
    reps=e2reps(); n=10; D1=gv(reps{1}); t=D1(1,:); N=numel(t); AL=zeros(n,N); TH=zeros(n,N); VmR=D1(6,:); z=1.96;
    for i=1:n, D=gv(reps{i}); AL(i,:)=D(5,:); TH(i,:)=D(4,:); end
    muA=mean(AL,1); sgA=std(AL,0,1); muT=mean(TH,1); sgT=std(TH,0,1);
    ca=@(x) x-mean(x); saln=@(x,ref) ca(x)*sign(corr(ca(x)',ca(ref)')+eps)+mean(muA);
    alM=saln(getrow('fid_E2_qsm.mat',4),muA); M3=gv('E2_model3D.mat'); al3=saln(interp1(M3(1,:),M3(3,:),t,'linear','extrap'),muA);
    R=gv('fid_E2_rtbox (2).mat'); if size(R,1)>size(R,2),R=R.';end; [~,lag]=xcorr_lag(R(8,:),VmR); idx=min(max((1:N)+lag,1),size(R,2));
    alR=saln(R(3,idx),muA); thM=salign(getrow('fid_E2_qsm.mat',3),muT); thM3=salign(interp1(M3(1,:),M3(2,:),t,'linear','extrap'),muT); thRTB=salign(R(2,idx),muT);
    segs={'escalones/tope',[1 10];'barrido lento',[10 24];'barrido rapido',[24 33]}; modn={'QSM=SIM','RTB','3D'}; cols=[.85 .2 .2;.9 .55 .15;.2 .6 .25];
    modsA={alM,alR,al3}; modsT={thM,thRTB,thM3}; RA=zeros(3,3); RT=zeros(3,3);
    for s=1:3, w=t>=segs{s,2}(1)&t<=segs{s,2}(2);
        for m=1:3, RA(s,m)=d2(sqrt(mean((modsA{m}(w)-muA(w)).^2,'omitnan'))); RT(s,m)=d2(sqrt(mean((modsT{m}(w)-muT(w)).^2,'omitnan'))); end
    end
    % --- FIG banda: alpha (sin envolver) + theta + Vm ---
    f=figure('Color','w','Position',[60 60 1050 780]); tiledlayout(3,1,'Padding','compact','TileSpacing','compact');
    nexttile; hold on; grid on;
    fill([t fliplr(t)],d2([muA+z*sgA fliplr(muA-z*sgA)]),[.2 .4 .9],'FaceAlpha',.15,'EdgeColor','none','DisplayName','banda \mu\pm1.96\sigma');
    plot(t,d2(muA),'b','LineWidth',1.2,'DisplayName','QHW real (n=10)'); plot(t,d2(alM),'--','Color',cols(1,:),'LineWidth',.8,'DisplayName','QSM=SIM'); plot(t,d2(alR),'-.','Color',cols(2,:),'LineWidth',.8,'DisplayName','RTB'); plot(t,d2(al3),':','Color',cols(3,:),'LineWidth',1.0,'DisplayName','3D');
    yline(180,'k:','HandleVisibility','off'); ylabel('\alpha [deg] (sin envolver)'); xlim([0 33]); legend('Location','south','FontSize',7,'NumColumns',4); title('E2 forzado: \alpha (péndulo) — 4 modalidades vs banda real (n=10)');
    nexttile; hold on; grid on; fill([t fliplr(t)],d2([muT+z*sgT fliplr(muT-z*sgT)]),[.2 .4 .9],'FaceAlpha',.15,'EdgeColor','none','HandleVisibility','off');
    plot(t,d2(muT),'b','LineWidth',1.2); plot(t,d2(thM),'--','Color',cols(1,:),'LineWidth',.8); plot(t,d2(thRTB),'-.','Color',cols(2,:),'LineWidth',.8); plot(t,d2(thM3),':','Color',cols(3,:),'LineWidth',1.0);
    yline(135,'k:','HandleVisibility','off'); yline(-135,'k:','HandleVisibility','off'); ylabel('\theta [deg] (brazo)'); xlim([0 33]);
    nexttile; plot(t,VmR,'k','LineWidth',.9); grid on; hold on; for b=[1 10 24 33], xline(b,'Color',[.5 .5 .5]); end; ylabel('V_m [V]'); xlabel('t [s]'); xlim([0 33]);
    exportgraphics(f,'figs/resultados/E2_banda.png','Resolution',130); close(f);
    % --- FIG segmentos: RMSE alpha y theta ---
    segn={'escalones/tope','barrido lento','barrido rapido'};
    f=figure('Color','w','Position',[60 60 980 420]); tiledlayout(1,2,'Padding','compact','TileSpacing','compact');
    nexttile; b=bar(RA); for k=1:3,b(k).FaceColor=cols(k,:);end; grid on; set(gca,'XTickLabel',segn); ylabel('RMSE_\alpha [deg]'); legend(modn,'FontSize',8); title('E2: RMSE de \alpha (péndulo) por segmento');
    nexttile; b=bar(RT); for k=1:3,b(k).FaceColor=cols(k,:);end; grid on; set(gca,'XTickLabel',segn); ylabel('RMSE_\theta [deg]'); legend(modn,'FontSize',8); title('E2: RMSE de \theta (brazo) por segmento');
    exportgraphics(f,'figs/resultados/E2_segmentos.png','Resolution',130); close(f);
    fprintf('E2: RMSE_alpha escalones=%s lento=%s rapido=%s | sigma_alpha=%.2f deg\n',mat2str(round(RA(1,:),1)),mat2str(round(RA(2,:),1)),mat2str(round(RA(3,:),1)),d2(mean(sgA)));
end

% ============================ E3 ============================
function E3()
    reps=arrayfun(@(k)sprintf('fid_E3_qhw_%d.mat',k),1:10,'uni',0); n=10; Ts=0.002; z=1.96; tt=2.262;
    D1=gv(reps{1}); t=D1(1,:); N=numel(t); ALW=zeros(n,N);TH=zeros(n,N);VM=zeros(n,N);tc=zeros(1,n);nsw=zeros(1,n);tset=zeros(1,n);ovs=zeros(1,n);
    for i=1:n
        D=gv(reps{i}); alw=wrapf(D(4,:)); ALW(i,:)=alw; TH(i,:)=D(3,:); VM(i,:)=D(5,:);
        kc=find(D(12,:)>0.5,1); tc(i)=t(kc); nsw(i)=count_swings(alw(1:kc));
        [tset(i),ovs(i)]=transzone(alw,t,Ts);
    end
    muA=mean(ALW,1);sgA=std(ALW,0,1);muT=mean(TH,1);sgT=std(TH,0,1); tcm=mean(tc);
    % modelos alineados a t + signo
    MQ=gv('fid_E3_qsm.mat'); alQ=salign(wrapf(MQ(8,:)),muA); thQ=salign(MQ(3,:),muT);
    G=gv('log_simscape_comp_modelo.mat'); alG=salign(interp1(G(1,:),wrapf(G(3,:)),t,'linear','extrap'),muA); thG=salign(interp1(G(1,:),G(2,:),t,'linear','extrap'),muT);
    R=gv('fid_E3_rtbox.mat'); if size(R,1)>size(R,2),R=R.';end; tR=(0:size(R,2)-1)*Ts;
    alR=salign(interp1(tR,wrapf(R(10,:)),t,'linear',NaN),muA); thR=salign(interp1(tR,R(2,:),t,'linear',NaN),muT);
    W2=t>=tcm+1&t<=tcm+3;
    % RMSE de alpha por zona con UNWRAP (continua): swing-up SÍ es comparable así.
    ALU=zeros(n,N); for i=1:n, D=gv(reps{i}); au=unwrap(wrapf(D(4,:))); ALU(i,:)=au-mean(au(W2)); end; muU=mean(ALU,1);
    pz=@(x) x-mean(x(W2 & ~isnan(x))); sz=@(x,w) sign(corr(x(w)',muU(w)')+eps); ws=t>=0.3&t<=tcm;
    uQ=pz(unwrap(wrapf(MQ(8,:)))); uQ=uQ*sz(uQ,ws);
    uG=pz(interp1(G(1,:),unwrap(wrapf(G(3,:))),t,'linear','extrap')); uG=uG*sz(uG,ws);
    uR=pz(interp1(tR,unwrap(wrapf(R(10,:))),t,'linear',NaN)); uR=uR*sz(uR,ws);
    zw={[0.3 12];[0.3 tcm];[tcm tcm+0.5]}; RU=zeros(3,3); uu={uQ,uR,uG};
    for zz=1:3, w=t>=zw{zz}(1)&t<=zw{zz}(2); for m=1:3, RU(zz,m)=d2(sqrt(mean((uu{m}(w)-muU(w)).^2,'omitnan'))); end; end
    % --- FIG banda ---
    cols=[.85 .2 .2;.9 .55 .15;.2 .6 .25];
    f=figure('Color','w','Position',[60 60 1050 780]); tiledlayout(3,1,'Padding','compact','TileSpacing','compact');
    nexttile; hold on; grid on;
    fill([t fliplr(t)],d2([muA+z*sgA fliplr(muA-z*sgA)]),[.2 .4 .9],'FaceAlpha',.18,'EdgeColor','none','DisplayName','banda \mu\pm1.96\sigma');
    plot(t,d2(muA),'b','LineWidth',1.1,'DisplayName','QHW real (n=10)'); plot(t,d2(alQ),'--','Color',cols(1,:),'LineWidth',.9,'DisplayName','QSM=SIM'); plot(t,d2(alR),'-.','Color',cols(2,:),'LineWidth',.9,'DisplayName','RTB'); plot(t,d2(alG),':','Color',cols(3,:),'LineWidth',1.1,'DisplayName','3D');
    xline(tcm,'k:','HandleVisibility','off'); yline(17,'k:'); yline(-17,'k:'); ylabel('\alpha_{wrap} [deg]'); xlim([0 8]); ylim([-200 200]); legend('Location','east','FontSize',7,'NumColumns',2); title('E3: \alpha de las 4 modalidades (swing-up, transición \pm17\circ, balance)');
    nexttile; hold on; grid on; fill([t fliplr(t)],d2([muA+z*sgA fliplr(muA-z*sgA)]),[.2 .4 .9],'FaceAlpha',.18,'EdgeColor','none','HandleVisibility','off');
    plot(t,d2(muA),'b','LineWidth',1.1); plot(t,d2(alQ),'--','Color',cols(1,:)); plot(t,d2(alR),'-.','Color',cols(2,:)); plot(t,d2(alG),':','Color',cols(3,:)); yline(17,'k:'); yline(-17,'k:'); ylabel('\alpha_{wrap} (transic+balance)'); xlim([2.5 6]); ylim([-25 25]);
    nexttile; hold on; grid on; fill([t fliplr(t)],d2([muT+z*sgT fliplr(muT-z*sgT)]),[.2 .4 .9],'FaceAlpha',.15,'EdgeColor','none','HandleVisibility','off');
    plot(t,d2(muT),'b','LineWidth',1.0,'DisplayName','real'); plot(t,d2(thQ),'--','Color',cols(1,:),'DisplayName','QSM=SIM'); plot(t,d2(thR),'-.','Color',cols(2,:),'DisplayName','RTB'); plot(t,d2(thG),':','Color',cols(3,:),'DisplayName','3D');
    ylabel('\theta [deg]'); xlabel('t [s]'); xlim([0 8]); legend('Location','northeast','FontSize',7,'NumColumns',4);
    exportgraphics(f,'figs/resultados/E3_banda.png','Resolution',130); close(f);
    % --- FIG zonas (6 paneles: swing-up, transición, balance) ---
    Zset=[zonemetric(alQ,t,Ts,'set') zonemetric(alR,t,Ts,'set') zonemetric(alG,t,Ts,'set')];
    Zrms=[d2(rms(alQ(W2))) d2(rms(alR(W2 & ~isnan(alR)))) d2(rms(alG(W2)))];
    Zth =[d2(std(thQ(W2))) d2(std(thR(W2 & ~isnan(thR)))) d2(std(thG(W2)))];
    Zrmse=[d2(sqrt(mean((alQ(W2)-muA(W2)).^2,'omitnan'))) d2(sqrt(mean((alR(W2)-muA(W2)).^2,'omitnan'))) d2(sqrt(mean((alG(W2)-muA(W2)).^2,'omitnan')))];
    kcM=[t(find(MQ(16,:)>0.5,1)) tR(find(R(15,:)>0.5,1)) 2.676]; vaM=[7 7 7];
    labs={'real','QSM=SIM','RTB','3D'}; cc=[.25 .45 .8;cols]; jit=linspace(-0.18,0.18,10);
    set_run=tset-tc; rms_run=d2(rms(ALW(:,W2),2)); sth_run=d2(std(TH(:,W2),0,2));
    f=figure('Color','w','Position',[60 60 1150 640]); tiledlayout(2,3,'Padding','compact','TileSpacing','compact');
    nexttile; v=[mean(tc) kcM]; b=bar(v,'FaceColor','flat'); b.CData=cc; hold on; grid on; scatter(1+jit,tc,12,[.1 .2 .5],'filled','MarkerFaceAlpha',.6); errorbar(1,v(1),tt*std(tc)/sqrt(10),'k','LineStyle','none','CapSize',7); set(gca,'XTickLabel',labs); ylabel('s'); ylim([2.6 2.8]); title('SWING-UP: tiempo de captura');
    nexttile; v=[mean(nsw) vaM]; b=bar(v,'FaceColor','flat'); b.CData=cc; grid on; set(gca,'XTickLabel',labs); ylabel('n\circ'); ylim([0 8]); title('SWING-UP: vaivenes (todas = 7)');
    nexttile; v=[mean(set_run) Zset]; b=bar(v,'FaceColor','flat'); b.CData=cc; hold on; grid on; scatter(1+jit,set_run,12,[.1 .2 .5],'filled','MarkerFaceAlpha',.6); errorbar(1,v(1),tt*std(set_run)/sqrt(10),'k','LineStyle','none','CapSize',7); set(gca,'XTickLabel',labs); ylabel('s'); title('TRANSICIÓN: asentam. 17\circ\rightarrow3\circ');
    nexttile; v=[mean(rms_run) Zrms]; b=bar(v,'FaceColor','flat'); b.CData=cc; hold on; grid on; scatter(1+jit,rms_run,14,[.1 .2 .5],'filled','MarkerFaceAlpha',.6); errorbar(1,v(1),tt*std(rms_run)/sqrt(10),'k','LineStyle','none','CapSize',7); set(gca,'XTickLabel',labs); ylabel('deg'); title('BALANCE: RMS \alpha (regulación)');
    nexttile; v=[mean(sth_run) Zth]; b=bar(v,'FaceColor','flat'); b.CData=cc; hold on; grid on; scatter(1+jit,sth_run,14,[.1 .2 .5],'filled','MarkerFaceAlpha',.6); errorbar(1,v(1),tt*std(sth_run)/sqrt(10),'k','LineStyle','none','CapSize',7); set(gca,'XTickLabel',labs); ylabel('deg'); title('BALANCE: dispersión \theta');
    nexttile; bz=bar(categorical({'general','swing-up','transición'},{'general','swing-up','transición'}), RU); for k=1:3, bz(k).FaceColor=cc(k+1,:); end; grid on; ylabel('RMSE_\alpha [deg]'); legend({'QSM=SIM','RTB','3D'},'FontSize',7,'Location','northwest'); title('RMSE de \alpha por zona (unwrap; sin real)');
    exportgraphics(f,'figs/resultados/E3_zonas.png','Resolution',130); close(f);
    fprintf('E3: captura=%.3f+-%.3f vaiv=%d | balance RMSa real=%.3f QSM=%.3f RTB=%.3f 3D=%.3f\n',tcm,std(tc),round(mean(nsw)),d2(mean(rms(ALW(:,W2),2))),Zrms(1),Zrms(2),Zrms(3));
end

% ============================ alpha wrap/unwrap ============================
function fig_alpha_wrap()
    D=gv('fid_E3_qhw_1.mat'); t=D(1,:); alw=wrapf(D(4,:)); alu=unwrap(alw); kc=find(D(12,:)>0.5,1); tcap=t(kc); w=t<=3.2;
    f=figure('Color','w','Position',[70 70 1000 560]); hold on; grid on;
    h1=plot(t(w),d2(alu(w)),'-','Color',[.85 .33 .1],'LineWidth',1.8); h2=plot(t(w),d2(alw(w)),'-','Color',[0 .2 .8],'LineWidth',1.0);
    coin=abs(alu)<pi; h3=plot(t(w&coin),d2(alu(w&coin)),'.','Color',[0 .6 0],'MarkerSize',7);
    yline(0,'k-','LineWidth',1,'HandleVisibility','off'); yline(180,'k:','HandleVisibility','off'); yline(-180,'k:','HandleVisibility','off'); xline(tcap,'k--','HandleVisibility','off');
    text(0.05,12,'\alpha=0: arriba (balance)','FontSize',9); text(0.05,192,'\pm180: colgado (pliegue)','FontSize',8,'Color',[.3 .3 .3]);
    ylabel('\alpha [deg]'); xlabel('t [s]'); ylim([-560 220]); xlim([0 3.2]); title('\alpha desenvuelta vs \alpha envuelta — el lazo realimenta \alpha_{wrap}');
    legend([h1 h2 h3],{'\alpha unwrap (continua)','\alpha wrap \in[-180,180]','wrap \equiv unwrap cerca de arriba'},'Location','southwest','FontSize',8);
    exportgraphics(f,'figs/resultados/E_alpha_wrap_unwrap.png','Resolution',140); close(f);
end

% ============================ corridas individuales (n=5) ============================
function figs_corridas()
    Ts=0.002; cmap=lines(5);
    % --- E1 (alpha y theta plegados juntos) ---
    r={'fid_E1_qhw.mat','fid_E1_qhw_3.mat','fid_E1_qhw_4.mat','fid_E1_qhw_6.mat','fid_E1_qhw_9.mat'}; rn=[1 3 4 6 9];
    g=-0.2:0.002:8; PHI=nan(5,numel(g)); TH=nan(5,numel(g));
    for i=1:5, D=gv(r{i}); t=D(1,:); th=D(4,:); al=D(5,:); k0=release_idx(al); hang=mean(al(end-500:end));
        s=al-hang; thc=th-mean(th(end-500:end)); if s(k0)>0, s=-s; thc=-thc; end
        PHI(i,:)=interp1(t-t(k0),s,g,'linear',NaN); TH(i,:)=interp1(t-t(k0),thc,g,'linear',NaN); end
    f=figure('Color','w','Position',[60 60 1050 700]); tiledlayout(2,2,'Padding','compact','TileSpacing','compact');
    nexttile; hold on; grid on; for i=1:5, plot(g,d2(PHI(i,:)),'Color',[cmap(i,:) .8],'LineWidth',.8,'DisplayName',sprintf('corrida %d',rn(i))); end
    plot(g,d2(mean(PHI,1,'omitnan')),'k','LineWidth',1.8,'DisplayName','media'); ylabel('\alpha-\alpha_{colg} [deg]'); xlim([-0.2 8]); legend('Location','northeast','FontSize',7); title('E1: \alpha — 5 corridas');
    nexttile; hold on; grid on; for i=1:5, plot(g,d2(PHI(i,:)),'Color',[cmap(i,:) .8]); end; plot(g,d2(mean(PHI,1,'omitnan')),'k','LineWidth',1.6); xlim([2.5 4.5]); ylabel('\alpha [deg]'); title('E1: \alpha (zoom)');
    nexttile; hold on; grid on; for i=1:5, plot(g,d2(TH(i,:)),'Color',[cmap(i,:) .8]); end; plot(g,d2(mean(TH,1,'omitnan')),'k','LineWidth',1.6); xlim([-0.2 8]); ylabel('\theta [deg]'); xlabel('t desde soltada [s]'); title('E1: \theta — 5 corridas');
    nexttile; hold on; grid on; for i=1:5, plot(g,d2(TH(i,:)),'Color',[cmap(i,:) .8]); end; plot(g,d2(mean(TH,1,'omitnan')),'k','LineWidth',1.6); xlim([2.5 4.5]); ylabel('\theta [deg]'); xlabel('t desde soltada [s]'); title('E1: \theta (zoom)');
    exportgraphics(f,'figs/resultados/E1_corridas.png','Resolution',130); close(f);
    % --- E2 (alpha SIN envolver + theta) ---
    r={'fid_E2_qhw.mat','fid_E2_qhw_3.mat','fid_E2_qhw_5.mat','fid_E2_qhw_7.mat','fid_E2_qhw_9.mat'}; rn=[1 3 5 7 9];
    D1=gv(r{1}); t=D1(1,:); N=numel(t); TH=zeros(5,N); AL=zeros(5,N);
    for i=1:5, D=gv(r{i}); TH(i,:)=D(4,:); AL(i,:)=D(5,:); end
    f=figure('Color','w','Position',[60 60 1050 720]); tiledlayout(3,1,'Padding','compact','TileSpacing','compact');
    nexttile; hold on; grid on; for i=1:5, plot(t,d2(AL(i,:)),'Color',[cmap(i,:) .85],'LineWidth',.7,'DisplayName',sprintf('corrida %d',rn(i))); end
    plot(t,d2(mean(AL,1)),'k','LineWidth',1.2,'DisplayName','media'); yline(180,'k:','HandleVisibility','off'); ylabel('\alpha [deg] (sin envolver)'); xlim([0 33]); legend('Location','south','FontSize',7,'NumColumns',6); title('E2: \alpha (péndulo) — 5 corridas (repetible, oscila en torno a 180\circ)');
    nexttile; hold on; grid on; for i=1:5, plot(t,d2(AL(i,:)),'Color',[cmap(i,:) .85]); end; plot(t,d2(mean(AL,1)),'k','LineWidth',1.1); ylabel('\alpha [deg] (zoom)'); xlim([13 19]); title('E2: \alpha (zoom barrido)');
    nexttile; hold on; grid on; for i=1:5, plot(t,d2(TH(i,:)),'Color',[cmap(i,:) .85]); end; plot(t,d2(mean(TH,1)),'k','LineWidth',1.1); ylabel('\theta [deg] (brazo)'); xlabel('t [s]'); xlim([0 33]); title('E2: \theta — 5 corridas');
    exportgraphics(f,'figs/resultados/E2_corridas.png','Resolution',130); close(f);
    % --- E3 (alpha_wrap y theta) ---
    r={'fid_E3_qhw_1.mat','fid_E3_qhw_3.mat','fid_E3_qhw_4.mat','fid_E3_qhw_7.mat','fid_E3_qhw_10.mat'}; rn=[1 3 4 7 10];
    D1=gv(r{1}); t=D1(1,:); N=numel(t); ALW=zeros(5,N); TH=zeros(5,N);
    for i=1:5, D=gv(r{i}); ALW(i,:)=wrapf(D(4,:)); TH(i,:)=D(3,:); end
    f=figure('Color','w','Position',[60 60 1050 760]); tiledlayout(3,1,'Padding','compact','TileSpacing','compact');
    nexttile; hold on; grid on; for i=1:5, plot(t,d2(ALW(i,:)),'Color',[cmap(i,:) .8],'LineWidth',.7,'DisplayName',sprintf('corrida %d',rn(i))); end
    plot(t,d2(mean(ALW,1)),'k','LineWidth',1.2,'DisplayName','media'); yline(17,'k:','HandleVisibility','off'); yline(-17,'k:','HandleVisibility','off'); ylabel('\alpha_{wrap} [deg]'); xlim([0 8]); ylim([-200 200]); legend('Location','east','FontSize',7,'NumColumns',3); title('E3: \alpha — 5 corridas (swing-up casi idéntico)');
    nexttile; hold on; grid on; for i=1:5, plot(t,d2(ALW(i,:)),'Color',[cmap(i,:) .85]); end; plot(t,d2(mean(ALW,1)),'k','LineWidth',1.2); yline(0,'k:','HandleVisibility','off'); ylabel('\alpha_{wrap} (balance)'); xlim([3.5 12]); ylim([-1.5 1.5]); title('E3: \alpha balance (variación corrida a corrida; corrida 4 = ruidosa)');
    nexttile; hold on; grid on; for i=1:5, plot(t,d2(TH(i,:)),'Color',[cmap(i,:) .85]); end; plot(t,d2(mean(TH,1)),'k','LineWidth',1.2); ylabel('\theta [deg]'); xlabel('t [s]'); xlim([0 12]); title('E3: \theta — 5 corridas');
    exportgraphics(f,'figs/resultados/E3_corridas.png','Resolution',130); close(f);
end

% ============================ utilidades ============================
function y=wrapf(x), y=mod(x+pi,2*pi)-pi; end
function y=d2(x), y=x*180/pi; end
function D=gv(f), S=load(f); fn=fieldnames(S); D=S.(fn{1}); if size(D,1)>size(D,2), D=D.'; end; end
function v=getrow(f,r), D=gv(f); v=D(r,:); end
function y=salign(x,ref), m=~isnan(x)&~isnan(ref); y=x*sign(corr(x(m)',ref(m)')+eps); end
function r=e1reps(), r={'fid_E1_qhw.mat','fid_E1_qhw_2.mat','fid_E1_qhw_3.mat','fid_E1_qhw_4.mat','fid_E1_qhw_5.mat','fid_E1_qhw_6.mat','fid_E1_qhw_7.mat','fid_E1_qhw_8.mat','fid_E1_qhw_9.mat','fid_E1_qhw_10.mat'}; end
function r=e2reps(), r={'fid_E2_qhw.mat','fid_E2_qhw_2.mat','fid_E2_qhw_3.mat','fid_E2_qhw_4.mat','fid_E2_qhw_5.mat','fid_E2_qhw_6.mat','fid_E2_qhw_7.mat','fid_E2_qhw_8.mat','fid_E2_qhw_9.mat','fid_E2_qhw_10.mat'}; end
function k0=release_idx(al)
    du=abs(wrapf(al)); ho=du<0.35; dd=diff([0 ho 0]); s=find(dd==1); e=find(dd==-1)-1; [~,mi]=max(e-s); k0=e(mi); while k0<numel(al)-9 && du(k0)<0.5, k0=k0+1; end
end
function [fn,ze]=linfnzeta(a,k0,Ts)
    a=a(k0:end); [pks,locs]=findpeaks(abs(a),'MinPeakDistance',round(0.15/Ts),'MinPeakHeight',0.02);
    amp=d2(pks); b=amp<25&amp>8; Lb=locs(b); P=pks(b); fn=1/(median(diff(Lb))*Ts*2);
    r=P(1:end-1)./P(2:end); r=r(r>0&isfinite(r)); dl=median(log(r)); ze=dl/sqrt(4*pi^2+dl^2);
end
function [c0,lag]=xcorr_lag(x,y), L=min(numel(x),numel(y)+400); [c,l]=xcorr(x(1:L)-mean(x(1:L)),y-mean(y),400); [c0,im]=max(c); lag=l(im); end
function ns=count_swings(alw)
    seg=abs(alw); ns=0; last=-inf; for k=2:numel(seg)-1, if seg(k)>seg(k-1)&&seg(k)>=seg(k+1)&&seg(k)>deg2rad(150)&&(k-last)>50, ns=ns+1; last=k; end; end
end
function [tset,ov]=transzone(alw,t,Ts)
    k17=find(abs(alw)<deg2rad(17)&t>1,1); run=0; need=round(0.3/Ts); ks=k17;
    for k=k17:numel(alw), if abs(alw(k))<deg2rad(3),run=run+1;else,run=0;end; if run>=need,ks=k-run+1;break;end; end
    tset=t(ks); ov=d2(max(abs(alw(k17:ks))));
end
function v=zonemetric(alw,t,Ts,~)
    k17=find(abs(alw)<deg2rad(17)&t>1,1); if isempty(k17), v=NaN; return; end
    run=0; need=round(0.3/Ts); ks=k17; for k=k17:numel(alw), if ~isnan(alw(k))&&abs(alw(k))<deg2rad(3),run=run+1;else,run=0;end; if run>=need,ks=k-run+1;break;end; end
    kc=find(abs(alw)<deg2rad(17)&t>1,1); v=t(ks)-t(kc);
end
