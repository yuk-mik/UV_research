%% ここでやること
% トリガが259個あるのかを確認する
% 隣のトリガとの差分が1000フレーム（理想）とどれくらい変わっているのかチェック
% トリガの立ったフレーム（黒画像提示→白画像提示に変わったフレーム）を配列で獲得すること


%% EEGを読み込む 1:'AF3', 2:'AFz' 3:'AF4', 4:'F3', 5:'FZ', 6:'F4', 
% 7:'Fp2', 8:'AF8', 9:'EX1'(入力なし), 10:'EX2'(フォトディテクタ)
i = 5;
mats = [];
mats = dir("filename/*.mat");
load(strcat(mats(i).folder,"/",mats(i).name));

% 以降ALL_dataのトリガを編集し、トリガタイミングのcsv出力を行う
ALL_data=[];
EEG_data=[];
ALL_data(:,:)=rawdata(:,:);
EEG_data(:,1:8) = rawdata(:,1:8);

disp('load rawdata');

%% トリガーを出力して、視覚的に閾値(どの値以下が画像提示タイミング（フォトディテクタに対する白画像提示タイミング）なのか)を見つける
% figure(1);
% 
% plot(ALL_data(:,10)); % EX2 フォトディテクタ、コマンドで別に打つと確認できる
% title("trigger Photoditector");


%% トリガデータを編集する
%理想的なトリガは
%約-800~-900の値をとっている時（黒い画面が提示されているとき）から約-3500~-11000の値をとる（白い画面が提示されている）ように立ち上がる。
%（自分の全部のデータを確認できていないので絶対かはわかっていない）

%1秒間(500フレーム)約-3500~-11000が続き，また約-800~-900が1秒間(500フレーム)続く。これを繰り返す
%現実的には例外的な値が存在したりする。（トリガが立ち始めて値が下がっているのに、また値が上がってギザギザする　など）
%そのせいで、取得したい値が下がり始めた部分以外もトリガと認識してしまう問題がある。（主に、値が上がり始めた部分(本来のトリガの500フレーム後)を認識する）
%これをなくすために取得したい値が下がり始めた部分（白画面→黒画面のとこ）を意図的になくす

%編集内容　→ 初めて-2000を下回ったフレームから600フレームを強制的に-15000にする
%ここでの閾値と、トリガの決定条件は以前のやり方と変わっていないので、代わりにトリガフレームを使って処理をしたとしても変化はないはず

% th_sに閾値を設定
th_s = -2000;
frame_n = 600;

for i=2:length(ALL_data)
    
    % 閾値より小さく、かつ、前のデータが閾値以上であれば、それをトリガーの開始とする
    if(ALL_data(i,10) < th_s && ALL_data(i-1,10) > th_s)
        x = min(i+frame_n - 1, length(ALL_data));
        ALL_data(i:x, 10) = -15000;
    end
end

%% 編集後閾値を設定　
trg_frame=[];% トリガーの始まりのフレーム数を取得する
th_s_edit=-15000;% ここに編集後閾値を入れる


%% 分析する全てのトリガーを取得
for i=2:length(ALL_data)
    
    % 編集後閾値（th_s_edit）とデータが一致、かつ、前のデータが閾値（th_s）より大きいとき、そのフレームをトリガーの開始とする
    if(ALL_data(i,10) == th_s_edit && ALL_data(i-1,10) > th_s)
        trg_frame = [trg_frame i];
    end
end

disp(['first frame ', num2str(trg_frame(1))]);% for debug
disp(['last frame ', num2str(trg_frame(end))]);% for debug
disp(['number of frames ', num2str(length(trg_frame))]);

%% トリガタイミングの確認
%　1つ前のトリガーとの間隔(diffに格納)が1000くらいだったら正しい（1s:刺激,1s:fixiation 500fpsで収録のため）

diff=trg_frame(2:end) - trg_frame(1:end-1);
plot(diff)


%% トリガーの出力
% trg_frameをcsv出力
% pythonで脳波データのイベントデータ作成のため

csvwrite("Trigger/" + subject + "_" + condition + "_trgger.csv", transpose(trg_frame));

%% トリガの確認
% 上のコードを実行した後、コマンドで確認する

% plot(ALL_data(:,10));

%% トリガの手直し
% n番目までのフレームを空にして、n+1番目を先頭にする
% n = 34
% trg_frame(1:n) = [] 