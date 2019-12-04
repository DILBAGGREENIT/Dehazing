clear all,close all,clc;
[p n]=uigetfile('*.*','Dark channel prior')
input_image = imread([n p]);
%input_image=imresize(input_image,[300 500]);
I=double(input_image)/255;
%figure;
%imshow(I);
%title('input image');
[h,w,c]=size(I);

%dark_chaanel channel
dark_chaanel_ori=ones(h,w);
dark_chaanel_extend=ones(h+8,w+8);
mask=4;

for i=1:h
    for j=1:w
        dark_chaanel_extend(i+mask,j+mask)=min(I(i,j,:));
    end
end


%gaussian, , prewitt, laplacian, log, average, unsharp, disk, motion

hy = fspecial('sobel');
hx = hy';
Iy = imfilter(double(I), hy, 'replicate');
Ix = imfilter(double(I), hx, 'replicate');
gradmag = sqrt(Ix.^2 + Iy.^2);





for i=1+mask:h+mask
    for j=1+mask:w+mask
        A=dark_chaanel_extend(i-mask:i+mask,j-mask:j+mask);
        dark_chaanel_ori(i-mask,j-mask)=min(min(A));
    end
end
dark_chaanel_ori=gradmag;
%imwrite(gradmag,'d.bmp');
A=220/255;

w_1=0.95;
t=ones(w,h);
t=1-w_1*dark_chaanel_ori/A;
t=max(min(t,1),0);
figure;
imshow(t);
imwrite(t,'b.png');
title(' ');
dark_chaanel_ori1=min(min(min(I(:,:,:))));
dark_chaanel_max1=zeros(w,h);
for i=1:h
    for j=1:w
        dark_chaanel_max1(i,j)=min(I(i,j,:));
    end
end
dark_chaanel_max=max(max(dark_chaanel_max1(:,:)));
t1=ones(h,w);
t2=ones(h,w);
for i=1:h
    for j=1:w
        t1(i,j)=(dark_chaanel_max-dark_chaanel_ori1)*(A-min(I(i,j,:)));
        t2(i,j)=(dark_chaanel_max-dark_chaanel_ori1)*A-(min(I(i,j,:))-dark_chaanel_ori1)*min(I(i,j,:));
        t(i,j)=t1(i,j)/t2(i,j);
    end
end
t=max(min(t,1),0);
figure;
imshow(t);
title(' ');

t0=0.1;
img_adjusted=zeros(h,w,c);
for i=1:c
    for j=1:h
        for l=1:w
            img_adjusted(j,l,i)=(I(j,l,i)-A)/max(t(j,l),t0)+A;
        end
    end
end
figure;
imshow(img_adjusted);
title('final image');



imwrite(img_adjusted,'fog.png');
