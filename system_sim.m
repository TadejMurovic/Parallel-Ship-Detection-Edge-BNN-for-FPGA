%% READ BNN 
L = 3;    % Layers (L-1) Hidden layers and 1 Output layer
S = 50;   % Hidden Neurons
I = 1200; % Inputs
O = 1;    % Outputs

path = '';                                                    % Path
for i = 1:L
   cat_path_w = strcat(path,'dump_w_',num2str(i-1),'.txt');               % Weight Files [0/1]
   cat_path_t = strcat(path,'dump_t_',num2str(i-1),'.txt');               % Comparator threshold Files [unsigned integers]
   fileID = fopen(cat_path_w,'r');
   formatSpec = '%d';
   cols = S;
   rows = S;
   if i == 1
       cols = I;
   elseif i == L
       rows = O;
   end
   Brain.l(i).w = fscanf(fileID,formatSpec,[cols rows]);
   fclose(fileID);
   fileID = fopen(cat_path_t,'r');
   formatSpec = '%d';
   Brain.l(i).th = fscanf(fileID,formatSpec,[rows 1])';
   fclose(fileID);   
end

%% RUN NEURON-MERGER AND CREATE VERILOG MODULE
% As in the paper, the first layer is merged with merger factor of 5.
% The merged layer is automatically coded in verilog and outputted.

N = 1200;
wfull = Brain.l(1).w;
thfull = Brain.l(1).th;
merge_factor = 5;

gcnt = 0;
for x = 1:merge_factor:size(wfull,2)
    w = wfull(:,x:x+merge_factor-1);
    %w = [ones(N,1) w];
    gcnt = gcnt + 1;
    neuron(gcnt).wei = w(:,1);
    for i = merge_factor
        cnt = 0;
        full = ones(N,1);
        for j = i:-1:2
            C = combnk(1:i,j);
            for k = 1:size(C,1)
               A = ones(N,1);
               for l = 1:size(C,2)
                  [j k/size(C,1) l/size(C,2)]
                  neuron(gcnt).testmat(cnt+1,C(k,l)) = 1;
                  if l == 1
                    A_first = w(:,C(k,l));
                  else
                    A = A & (A_first == w(:,C(k,l)));  
                  end
               end
               A = A & full;
               full = full & ~A;
               cnt = cnt + 1;
               neuron(gcnt).mat(:,cnt) = A;
               neuron(gcnt).size(cnt)  = sum(A); 
               if merge_factor == 2
                  cnt = cnt + 1; 
                  neuron(gcnt).mat(:,cnt) = ~A;
                  neuron(gcnt).size(cnt)  = sum(~A); 
               end
            end
        end
        neuron(gcnt).sum_nb = cnt;
    end
end
for i = 1
    N = 1200;
    M = 50;
    lay = i;
    bits = ceil(log2(N+1)); 
    cat_path = strcat('ship_merge_model_',num2str(i-1),'.txt'); 
    fid = fopen(cat_path,'w');

    % Generate
    fprintf(fid,'`timescale 1ns / 1ps');
    fprintf(fid,'\n\n');
    fprintf(fid,strcat('module layer_',num2str(i-1),'(in, out'));
    fprintf(fid,');\n\n');

    fprintf(fid,'  input [%d:0] in;\n',N-1);
    fprintf(fid,'  output reg [%d:0] out;\n',M-1);
    %merge_factor = merge_factor + 1;
    cnt = 0;
    for ii = 0:merge_factor:M-1
       fprintf(fid,'  reg [%d:0] weighted%d;\n',N-1,cnt);
       fprintf(fid,strcat('  reg [%d:0] w%d = %d''b'),N-1,cnt,N);
       for j = 1:N
           fprintf(fid,'%d',neuron(cnt+1).wei((size(neuron(cnt+1).wei,1)+1)-j)); 
       end
       fprintf(fid,';\n');
       cnt = cnt + 1;
    end

    fprintf(fid,'\n\n');
    fprintf(fid,'  integer idx;\n');
    fprintf(fid, '  always @* begin\n');
    fprintf(fid, '    for( idx = 0; idx<%d; idx = idx + 1) begin\n',N);
    for ii = 0:cnt-1
       fprintf(fid,'      weighted%d[idx] = ((w%d[idx])~^(in[idx]));\n',ii,ii); 
    end
    fprintf(fid,'    end\n');
    fprintf(fid,'  end\n');

    fprintf(fid,'\n\n');
    for ii = 0:cnt-1
        for jj = 0:neuron(1).sum_nb-1
            bits = ceil(log2(neuron(ii+1).size(jj+1)+1));                    
            fprintf(fid,'  reg [%d:0] t%d_%d;\n',bits,ii,jj); 
        end
    end

    fprintf(fid,'\n\n');

    bits = ceil(log2(N+1)) + 1;
    for ii = 0:M-1                   
        fprintf(fid,'  reg signed [%d:0] t_ss%d;\n',bits,ii); 
    end

    fprintf(fid,'\n\n');
    fprintf(fid, '  always @* begin\n');
    for ii = 0:cnt-1
        for jj = 0:neuron(1).sum_nb-1
            fprintf(fid,'    t%d_%d = ',ii,jj); 
            valid = neuron(ii+1).mat(:,jj+1);
            if sum(valid) > 0
                for j = 0:N-1
                    if valid(j+1) == 1
                        if j == N-1
                            fprintf(fid, 'weighted%d[%d];\n',ii,j);
                        elseif sum(valid(j+2:end)) == 0 
                            fprintf(fid, 'weighted%d[%d];\n',ii,j);
                        else
                            fprintf(fid, 'weighted%d[%d] + ',ii,j);
                        end
                    end
                end   
            else
                fprintf(fid, '0;\n',ii,j);   
            end
        end
    end
    fprintf(fid,'  end \n');

    fprintf(fid,'\n\n');
    fprintf(fid, '  always @* begin\n');
    ncnt = 0;
    signs = neuron(1).testmat(:,2:end) ~=  neuron(1).testmat(:,1);
    signs = [zeros(size(signs,1),1) signs];
    thfullold = thfull;
    cntdbg0 = 0;
    cntdbg1 = 0;
    for ii = 0:cnt-1
        for jj = 0:merge_factor-1
            %fprintf(fid,'    out[%d] = $signed(',ncnt);
            fprintf(fid,'    t_ss%d = (',ncnt);
            add_x = 0;
            for kk = 0:neuron(1).sum_nb-1
                if merge_factor == 2
                    if kk == neuron(1).sum_nb-1
                        fprintf(fid, 't%d_%d);\n',ii,kk);
                        %fprintf(fid, 't%d_%d',ii,kk);
                    elseif jj == 0
                        fprintf(fid, 't%d_%d + ',ii,kk);
                    else
                        add_x = add_x + neuron(ii+1).size(kk+2);
                        fprintf(fid, 't%d_%d - ',ii,kk);
                    end                       
                else
                    if kk == neuron(1).sum_nb-1
                        fprintf(fid, 't%d_%d);\n',ii,kk);
                        %fprintf(fid, 't%d_%d)',ii,kk);
                    elseif signs(kk+2,jj+1) == 0
                        fprintf(fid, 't%d_%d + ',ii,kk);
                    else
                        add_x = add_x + neuron(ii+1).size(kk+2);
                        fprintf(fid, 't%d_%d - ',ii,kk);
                    end
                end
            end
            fprintf(fid,'    out[%d] = $signed(t_ss%d)',ncnt,ncnt);
            ncnt  = ncnt + 1;

            thfull(ncnt) = thfull(ncnt) - add_x;
            bits = ceil(log2(abs(thfull(ncnt))+1)) + 1;
            if bits == -inf
                bits = 1;
            end
            if thfull(ncnt) >= 0
                fprintf(fid,'  >= $signed(%d''sd%d);\n',bits,abs(thfull(ncnt)));
                cntdbg0 = cntdbg0 + 1;
            else
                fprintf(fid,'  >= $signed(-%d''sd%d);\n',bits,abs(thfull(ncnt)));    
                cntdbg1 = cntdbg1 + 1;
            end
        end
    end
    fprintf(fid,'  end \n');

    fprintf(fid,'endmodule');
    fclose(fid);  
end  

%% MAKE HDL CODE FOR ALL LAYERS WITH STRAIGHT-FORWARD IMPLEMENTATION
% For synthesis only the second and output layer are used. The first one is
% the merged model.
make_parallel('',[1200 2 50]);


%% SYSTEM TEST
% Runs pre-processing algorithms + BNN inference in a sliding window fashion + post-processing algorithms
close all;
clearvars -except Brain L
im = imread('ships-in-satellite-imagery/scenes/scenes/sfbay_1.png');  %Image Path

%--------------------------------------------------------------------------
% Pre-processing
im_format = rgb2gray(im);
im_format = imresize(im_format,0.125);
im_format_color = imresize(im,0.125);
i = 4;
im_format = (floor(double(im_format)*(2^-(8-i))));
X  = size(im_format,2);
Y  = size(im_format,1);

%--------------------------------------------------------------------------
% BNN sliding window
KS = 5;
ycnt = 0;
for y = (KS+1):1:(Y-KS-1)
    ycnt = ycnt + 1;
    xcnt = 0;
    for x = (KS+1):1:(X-KS-1)
        disp(strcat('X:',num2str(x/(X-KS-1)),'Y:',num2str(y/(Y-KS-1))));
        xcnt = xcnt + 1;
        vals = im_format((y-KS+1):(y+KS),(x-KS+1):(x+KS));
        vals = vals(:); 
        vals = de2bi(vals,'left-msb',4);
        vals = vals';
        vals = vals(:)';
        valslum = vals;
        
        % COLOR BASED
        mosaic = [];
        for c = 1:3
            cim = im_format_color((y-KS+1):(y+KS),(x-KS+1):(x+KS),c);
            i = 4;
            cim = (floor(double(cim)*(2^-(8-i))));
            cim = cim(:);
            cim = de2bi(cim,'left-msb',i);
            cim = cim';
            cim = cim(:)';
            mosaic = [mosaic cim];
        end
        vals = mosaic;
            
        check = 1;       
        BrainOutput = evalbnn(Brain, vals, L);
        im_response(ycnt,xcnt) = BrainOutput*check;        
    end
end

%--------------------------------------------------------------------------
% Post-processing
im_response_lowed = imgaussfilt(double(im_response),4);
im_response_lowed = im_response_lowed/max(max(im_response_lowed));
im_response_lowed(im_response_lowed < 0.22) = 0;
selection = imregionalmax(im_response_lowed);
[xi yi] = find(selection);
ids = ([yi xi]+5)*8;

close all;
imshow(im); hold on;
RS = 5*8;
for i = 1:length(ids)
    rectangle('Position', [ids(i,1)-RS ids(i,2)-RS 2*RS 2*RS],'EdgeColor','y','LineWidth',2); hold on;     
end





