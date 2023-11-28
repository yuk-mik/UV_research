
%% 描画チェック用プログラム
data = rawdata(:,1:10);

%EEG {'AF3','AFz','AF4','F3','FZ','F4','F10','Fp2'}
figure(1);
plot(data(:,1));
title('AF3');

figure(2);
plot(data(:,2));
title('AFz');

figure(3);
plot(data(:,3));
title('AF4');

figure(4);
plot(data(:,4));
title('F3');

figure(5);
plot(data(:,5));
title('FZ');

figure(6);
plot(data(:,6));
title('F4');

%EOG {'F10','Fp2'}　目の横、目の上（近い端子を記載）
figure(7);
plot(data(:,7));

figure(8);
plot(data(:,8));

%PhotoD
figure(10);
plot(data(:,10));
title('Photoditector');



