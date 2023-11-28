function [rawdata] = PolymateMini_SSSEP_8ch_ito(subject, condition, rectime)
% subject: 被験者名
% condition: 実験条件名
nowtime = datestr(now, 30); % 保存ファイル名用に現時間を取得

% OSで共通のキー配置にする
myKeyCheck;
%:l
MEL_CTRL;
MEL_SAMPLE_COMPORT	= 'COM6'; % COMポート番号
MEL_SAMPLE_UNITSIZE	= 1;
MEL_SAMPLE_UNIT_N	= 10000; %SIZE 1 のUNITを 10000個確保 → 10000/ 1000Hz =10秒分
MEL_SAMPLE_FREQ		= 500; %サンプリング周波数
% MEL_SAMPLE_LIST_CH = [MELCTRL_DEVTYPE_EEG+1 MELCTRL_DEVTYPE_EEG+2 MELCTRL_DEVTYPE_EEG+3 MELCTRL_DEVTYPE_EEG+4 MELCTRL_DEVTYPE_EEG+5 MELCTRL_DEVTYPE_EEG+6 MELCTRL_DEVTYPE_EEG+7 MELCTRL_DEVTYPE_EEG+8 MELCTRL_DEVTYPE_EXT+1 MELCTRL_DEVTYPE_EXT+2]; % EEG 5チャネル+EXT 1
MEL_SAMPLE_LIST_CH = [
    MELCTRL_DEVTYPE_EEG+1 MELCTRL_DEVTYPE_EEG+2 MELCTRL_DEVTYPE_EEG+3 ...
    MELCTRL_DEVTYPE_EEG+4 MELCTRL_DEVTYPE_EEG+5 MELCTRL_DEVTYPE_EEG+6 ...
    MELCTRL_DEVTYPE_EEG+7 MELCTRL_DEVTYPE_EEG+8 ...
    MELCTRL_DEVTYPE_EXT+1 MELCTRL_DEVTYPE_EXT+2];   % チャンネルの設定
CH_NAME = {'AF3' 'AFz ' 'AF4' 'F3' 'FZ' 'F4' 'F10' 'Fp2' 'EX1' 'EX2'};
RECORD_TIME=rectime*60+20; %計測時間 60分 %30分にする。(途中でやめることも可)
GAIN=100;
 

% Polymate Mini Init
fprintf('[Init]');
IS_INIT = mel4mex('Init');
if IS_INIT == 0
    fprintf(' NG\n');
    return;
else
    fprintf(' OK\n'); 
end

% Polymate Mini Open
fprintf('[Open]');
HANDLE = mel4mex('Open', MEL_SAMPLE_COMPORT, MEL_SAMPLE_UNITSIZE, MEL_SAMPLE_UNIT_N, MEL_SAMPLE_FREQ);
if( HANDLE <= 0 )
    fprintf(' NG\n');
    fprintf('[Term]\n');
    mel4mex('Term');
    return;
end
fprintf(' HANDLE: %d\n', HANDLE);

% try
fprintf('[SetCh]');
CH_N = size(MEL_SAMPLE_LIST_CH, 2);
ret = mel4mex('SetCh', HANDLE, CH_N, MEL_SAMPLE_LIST_CH); % チャネルセット

EEG_CH = 1:8;% 計測するチャンネル数分に変更
% EOG_CH = 7:8;% おそらく使わないチャンネルをここに記入する
TRG_CH = CH_N-1;% 恐らくこれはEX1 % トリガーチャンネル (これを二つ作る?)
TRG_CH2 = CH_N; % EX2を作る => 下のfigure()で表示されるように書く

% i = 1;CH_N-2 => EX1, EX2を除いた波形を表している?
for i=1:CH_N-2
    ret = mel4mex('SetChInfo', HANDLE, i, MELCTRL_CH_GAIN, GAIN);
end

[result info]=mel4mex('GetChInfo', HANDLE, 1, MELCTRL_CH_GAIN); % チャネルセット

if ret == 0
    fprintf(' NG\n');
    fprintf('[Close]\n');
    mel4mex('Close', HANDLE);
    fprintf('[Term]\n');
    mel4mex('Term');
    return;
else
    fprintf(' OK\n');
end

% インピーダンス計測
    fprintf('[GetImpedance]');
    IMPD = mel4mex('GetImpedance', HANDLE);
    if IMPD == 0
        fprintf(' NG\n');
    else
        fprintf(' OK\n');
        fprintf(' Impedance:');
        for itemImpd = IMPD
            fprintf(' %5f [k ohm]', itemImpd*0.001); %キロオーム単位で表示
        end
        fprintf('\n');
    end


pause(5)
fprintf('[Acquision] Start...\n');
[B1,A1] = butter(5,[5/(MEL_SAMPLE_FREQ/2) 50/(MEL_SAMPLE_FREQ/2)]); %フィルタ設計 5-50Hz
[B2,A2] = butter(5,[5/(MEL_SAMPLE_FREQ/2) 30/(MEL_SAMPLE_FREQ/2)]); %フィルタ設計 5-30Hz
Zf1 = [];
Zf2 = [];
data1 = [];
data2 = [];
rawdata=[];
% grand_cyc_epoched_data=[];
loop_cnt=1;
grandepoch=[];

ch_combi = nchoosek(1:CH_N-3,2);%%sampleにはこの行がない%%

mel4mex('StartAcquision', HANDLE); % 計測開始
pause(5)

tic
scrcz = get(groot, 'ScreenSize');
fig1=figure('Position', [scrcz(3)/2 50 scrcz(3)/3 scrcz(4)-130]);

disp('Hold down Esc key to stop ASSR recording >');
reference_time = datetime('now', 'Format', 'dd-MMM-yyyy HH:mm:ss.SSS');% 一応取得しておく
% 時間取得用配列
first_time = [];
%tttime = [];
flug = 0;

while 1
   escKey = KbName('Escape');           
   [keyIsDown, secs, keyCode] = KbCheck;
    if (toc > RECORD_TIME) | keyCode(escKey)    % RECORD_TIMEを超えるかEscキーが押されたら計測終了
        break;
    end
    pause(1) %1秒ごとにデータ解析
    %tttime = [tttime datetime('now', 'Format', 'dd-MMM-yyyy HH:mm:ss.SSS')];
    UNIT_N = mel4mex('CheckAcqUnitN', HANDLE); %計測データチェック
    if UNIT_N > 0 % 新規獲得データの有無
        if flug == 0
            first_time = [first_time datetime('now', 'Format', 'dd-MMM-yyyy HH:mm:ss.SSS')];
            flug = flug + 1;% もう入らないようにフラグを更新
        end
        tempdata = mel4mex('ReadAcqDataN', HANDLE, UNIT_N)/GAIN*(6/2^16)*10^6; %マイクロボルトに変換
        [tempdata1,Zf1] = filter(B1, A1, tempdata',Zf1); %フィルタ適用 5-50Hz
        [tempdata2,Zf2] = filter(B2, A2, tempdata',Zf2); %フィルタ適用 5-30Hz
        data1 = [data1;tempdata1]; %フィルタ(5-50Hz)のデータ連結
        data2 = [data2;tempdata2]; %フィルタ(5-30Hz)のデータ連結
        rawdata=[rawdata; tempdata'];
        data3 = data1(end-3*MEL_SAMPLE_FREQ+1:end,:); %data1の最新データ 3秒分のデータ抽出
        data4 = data2(end-3*MEL_SAMPLE_FREQ+1:end,:); %data2の最新データ 3秒分のデータ抽出
        
        rawdata2s=rawdata(end-3*MEL_SAMPLE_FREQ+1:end,:); %rawdataの最新データ 3秒分のデータ抽出

        
        figure(fig1);subplot(3,1,1)
        plot([1:MEL_SAMPLE_FREQ*3]/MEL_SAMPLE_FREQ,data4(:,EEG_CH)); % プロット [EEG_CH EOG_CH]
        axis([1/MEL_SAMPLE_FREQ MEL_SAMPLE_FREQ*3/MEL_SAMPLE_FREQ -50 50])
        title(['EEG, ' num2str(toc) 'sec']);
        xlabel('time (s)');
        ylabel('uV');
        legend(CH_NAME(EEG_CH));%[EEG_CH EOG_CH]
        
        % EX1の表示
        figure(fig1);subplot(3,2,4)
        plot(rawdata2s(:,TRG_CH))
        %axis([0 1500 -10^4 0])
        axis([0 1500 -10^4 10^4])
        title('TRG');
        
        % EX2の表示 %% coded by shimada
        figure(fig1);subplot(3,3,4)% あるいは、subplot(3, 2, 1)とかでも良いかも
        plot(rawdata2s(:,TRG_CH2))
        axis([0 1500 -10^4 10^4])
        title('PhotoDct');
        
        %trg=[];
        %for i=2:length(rawdata2s)      
        %    if( (rawdata2s(i,TRG_CH)) < -100 && (rawdata2s(i-1,TRG_CH)) > -100 ) % trig check
        %        trg(end+1)=i;
        %    end 
        %end
%{
        if(length(trg) > 2 && ( (length(trg(1):trg(3))  > MEL_SAMPLE_FREQ*2-2) && (length(trg(1):trg(3))  < MEL_SAMPLE_FREQ*2+2)))
            
            epoched_data=rawdata2s(trg(1):trg(3)-1,EEG_CH);
%             epoched_data=rawdata2s(trg(1):trg(3)-1,1:CH_N-3);
            [p,q]=rat(MEL_SAMPLE_FREQ*2/length(epoched_data),0.0001);
            epoched_data=resample(epoched_data,p,q);
            
            grandepoch=cat(3,grandepoch,epoched_data);

            if( size(epoched_data,1) == MEL_SAMPLE_FREQ*2 )
                
                %フーリエ変換
                Y = fft(epoched_data);
                FT(:,:,loop_cnt)=Y;
                P(:,:,loop_cnt)= sqrt(Y.*conj(Y));
                
                
                if(size(FT,3) > 30)
                    FT_mov=FT(:,:,end-29:end);
                    P_mov=P(:,:,end-29:end);
                else
                    FT_mov=FT;
                    P_mov=P;
                end
            
                            
                len =length(epoched_data);
                f=MEL_SAMPLE_FREQ/2*linspace(0,1,len/2+1);
                
                %シングルトライアルフーリエ変換結果
                figure(fig1);subplot(3,2,3)
                plot(f(21:91),P(21:91,:,loop_cnt));
                title('Fourier transform');
                xlabel('Hz');
                ylabel('Power');
                legend(CH_NAME(EEG_CH));
                loop_cnt=loop_cnt+1;     
                
                if(loop_cnt > 2)
                    

                    for ch_num=1:size(epoched_data,2)
                        ITPC(:,ch_num,:)=squeeze(abs(mean(squeeze(FT(:,ch_num,:))./abs(squeeze(FT(:,ch_num,:))),2)));
                    end
                    
                    
%                     for i_combi = 1:size(ch_combi,1)
%                         PLV(:,i_combi) = abs(mean(squeeze(FT_mov(:,ch_combi(i_combi,1),:)) .* conj(squeeze(FT_mov(:,ch_combi(i_combi,2),:)))...
%                             ./ abs(squeeze(FT_mov(:,ch_combi(i_combi,1),:))) ./ abs(squeeze(FT_mov(:,ch_combi(i_combi,2),:))),2));
%                     end
                                                            
                    %加算平均フーリエ変換結果
                    figure(fig1);subplot(3,2,5); plot(f(21:91),ITPC(21:91,:));
                    title(['PLI ' num2str(round(toc))]);xlabel('Hz');ylabel('PLI');legend(CH_NAME(EEG_CH));
                    
                    figure(fig1); subplot(3,2,6); plot(f(21:91),mean(ITPC(21:91,:),2)*5)
                    title(['PLI ' num2str(round(toc))]);xlabel('Hz');ylabel('avgPLI');
                 
%                     figure(fig1);subplot(4,2,7); plot(f(21:91),PLV(21:91,:));
%                     title(['PLV ' num2str(round(toc))]);xlabel('Hz');ylabel('PLV');
%                     
%                     figure(fig1);subplot(4,2,8);plot(f(21:91),mean(PLV(21:91,:),2)*28)
%                     title(['PLV ' num2str(round(toc))]);xlabel('Hz');ylabel('avgPLV');
                    

                end
            end
        end
        %}
    else
        disp('No New Data');
    end
end

toc
mel4mex('StopAcquision', HANDLE); % 計測終了

% Polymate Mini Close
fprintf('[Close]\n');
mel4mex('Close', HANDLE);
fprintf('[Term]\n');
mel4mex('Term');

close all
save(['data/SSSEP_' nowtime '_' subject '_' condition '.mat'])
% save(['data/rest_' nowtime '_' subject '.mat'])

% スタート時刻表示
disp(reference_time(1,1));

end
