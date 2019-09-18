%%
close all;
clear all;


cnt = 0;
cntpos = 0;
cntneg = 0;
Files=dir('ANTS/ships-in-satellite-imagery/shipsnet/shipsnet/*.*');
for k=3:length(Files)
    disp(num2str(k/length(Files)));
    FileNames=Files(k).name;
    im = imread(strcat('ANTS/ships-in-satellite-imagery/shipsnet/shipsnet/',FileNames));
    
    % COLOR BASED
    mosaic = [];
    for c = 1:3
        cim = im(:,:,c);
        cim = imresize(cim,0.125);
        i = 4;
        cim = (floor(double(cim)*(2^-(8-i))));
        cim = cim(:);
        cim = de2bi(cim,'left-msb',i);
        cim = cim';
        cim = cim(:)';
        mosaic = [mosaic cim];
    end
    im_format = mosaic;

    % LUMA BASED
%     im_format = rgb2gray(im);
%     im_format = imresize(im_format,0.125);
%     i = 4;
%     im_format = (floor(double(im_format)*(2^-(8-i))));    
%     im_format = im_format(:);    
%     im_format = de2bi(im_format,'left-msb',i);
%     im_format = im_format';
%     im_format = im_format(:)';
    
    label = str2num(FileNames(1));
    im_format = [im_format label]; 
    cnt = cnt + 1;
    cntpos = cntpos + (label == 1);
    cntneg = cntneg + (label == 0);
    mat(cnt,:) = im_format;    
end

binfeat = mat;

binfeat = binfeat(randperm(length(binfeat)),:);
pause(2.0);

LEN = size(binfeat,1);
infeat_train = binfeat(1:3200,:);
infeat_valid = binfeat(3201:3500,:);
infeat_test = binfeat(3501:end,:);
% id  = round(2*length(binfeat)/3);
% id6 = round(2*length(binfeat)/3/6);
% infeat_train = binfeat(1:id-id6,:);
% infeat_valid = binfeat((id-id6+1):id,:);
% infeat_test  = binfeat(id+1:end,:);

infeat_train = infeat_train(1:round(size(infeat_train,1)),:);
infeat_valid = infeat_valid(1:round(size(infeat_valid,1)),:);
infeat_test  = infeat_test(1:round(size(infeat_test,1)),:);

fileID = fopen('formatted_datasets/ships/ships_train.txt','w');
for i = 1:size(infeat_train,1)
    i/size(infeat_train,1)
    for j = 1:size(infeat_train,2)
        fprintf(fileID,'%d ',infeat_train(i,j));
    end
    fprintf(fileID,"\n");
end
fclose(fileID);

fileID = fopen('formatted_datasets/ships/ships_valid.txt','w');
for i = 1:size(infeat_valid,1)
    i/size(infeat_valid,1)
    for j = 1:size(infeat_valid,2)
        fprintf(fileID,'%d ',infeat_valid(i,j));
    end
    fprintf(fileID,"\n");
end
fclose(fileID);

fileID = fopen('formatted_datasets/ships/ships_test.txt','w');
for i = 1:size(infeat_test,1)
    i/size(infeat_test,1)
    for j = 1:size(infeat_test,2)
        fprintf(fileID,'%d ',infeat_test(i,j));
    end
    fprintf(fileID,"\n");
end
fclose(fileID);

return



