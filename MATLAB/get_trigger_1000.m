%% EEGを読み込む 1:'AF3', 2:'AFz' 3:'AF4', 4:'F3', 5:'FZ', 6:'F4', 
% 7:'Fp2', 8:'AF8', 9:'EX1', 10:'EX2'(フォトディテクタ)

%ALL_dataは全て、EEG_dataはトリガ以外 EEG_dataを加工していく
ALL_data=[];
EEG_data=[];
ALL_data(:,:)=rawdata(:,:);
EEG_data(:,1:8) = rawdata(:,1:8);

%% 時間同期用に最初の部分を切る(データをなくす)

%EEG_data(1:15000,:)=[];
%ALL_data(1:15000,:)=[];
disp('load rawdata');

%% トリガーを出力して、視覚的に閾値(どの値以上がクリック音の始まりか?)を見つける
figure(1);
%subplot(2,1,1);
%plot(ALL_data(:,9)); % EX1 
%title("trigger EX1");
%subplot(2,1,2);
plot(ALL_data(:,10)); % EX2 フォトディテクタ
title("trigger Photoditector");

%% 閾値を設定
trg_index0=[];% トリガーの始まりの行数を取得する
th_s=-2000;% ここに閾値を入れる% 小さいほうに合わせる(一発目のトリガーだけに引っかかるだけでよさそう)
%% 分析する全てのトリガーを取得
for i=2:length(ALL_data)
    % 閾値がプラスの場合は、ここの2つの不等号が逆になる
    if(ALL_data(i,10) < th_s && ALL_data(i-1,10) > th_s)% 閾値より小さく、前のデータが閾値より大きければ、それをトリガーの開始とする
        trg_index0(end+1)=i;
    end
end

disp(trg_index0(1));% for debug
disp(trg_index0(end));% for debug
length(ALL_data);

%% トリガタイミングの確認
%　1つ前のトリガーとの間隔が1000くらいだったら正しい（1s:刺激,1s:fixiation 500fpsで収録のため）
%　trg_index1が提示画像分のトリガタイミング

%trg_data0=zeros(1,length(EEG_data));
%trg_data0(trg_index0)=-1000;
diff0=trg_index0(2:end) - trg_index0(1:end-1);

% %　diff0を見て、正しくないトリガータイミングを消す
% 
% for i=1:length(diff0)-1
%     if(diff0(i) > 700)
%         trg_index0(i+1)=trg_index0(i+1);
%     elseif(100 <= diff0(i) && diff0(i) <= 700 && 100 >= diff0(i+1) && diff0(i+1) >= 700)
%         trg_index0(i+1)=0;
%     elseif(100 <= diff0(i) && diff0(i) <= 700 && 100 <= diff0(i+1) && diff0(i+1) <= 700)
%         trg_index0(i+1)=trg_index0(i+2);
%     else
%         trg_index0(i+1)=0;
%     end
% end
% 
% 
% s = 1;
% for i=1:length(trg_index0)
%     if (trg_index0(i) ~= 0)
%         trg_index1(s) = trg_index0(i);
%         s = s+1;
%     end
% end
% 
% % diff1が全て1000くらいだったらok
% diff1=trg_index1(2:end) - trg_index1(1:end-1);

