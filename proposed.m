clear all,close all,clc;
[p n]=uigetfile('*.*','Dark channel prior')
input_image = imread([n p]);
input_image=imresize(input_image,[300 500]);

figure,imshow(input_image),title('Input image');
input=input_image;
%Step 1 Convert image to L*a*b* color space

convert2lab = makecform('srgb2lab');
LAB = applycform(input_image, convert2lab); 


L = LAB(:,:,2); 
LAB(:,:,2) = adapthisteq(L,'NumTiles', [5 5],'ClipLimit',0.003);

L = LAB(:,:,1); 
LAB(:,:,1) = adapthisteq(L,'NumTiles', [5 5],'ClipLimit',0.003);

L = LAB(:,:,3); 
LAB(:,:,3) = adapthisteq(L,'NumTiles', [5 5],'ClipLimit',0.003);

% Convert 2 RGB  space
convert2rgb  = makecform('lab2srgb');
J = applycform(LAB, convert2rgb ); 

%Step 3 now apply dark_channel channel prior algorithm
input_image=J;
input_image=double(input_image)/255;

[h,w,c]=size(input_image);

dark_channel_ori=ones(h,w);
dark_channel_extend=ones(h+8,w+8);
mask=4;

for i=1:h
    for j=1:w
        gradient_profile_extend(i+mask,j+mask)=mean(input_image(i,j,:));
    end
end
for i=1+mask:h+mask
    for j=1+mask:w+mask
        A=gradient_profile_extend(i-mask:i+mask,j-mask:j+mask);
        gradient_profile_ori(i-mask,j-mask)=mean(mean(A));
    end
end
figure;
imshow(gradient_profile_ori);
title('gradient_profile channel measured');
A=220/255;

w_1=0.90;
t=ones(w,h);
t=1-w_1*gradient_profile_ori/A;
t=max(min(t,1),0);
figure;
imshow(t);
title('Input Depth');

gradient_profile_ori1=min(min(min(input_image(:,:,:))));
gradient_profile_max1=zeros(w,h);
for i=1:h
    for j=1:w
        gradient_profile_max1(i,j)=min(input_image(i,j,:));
    end
end
gradient_profile_max=max(max(gradient_profile_max1(:,:)));
t1=ones(h,w);
t2=ones(h,w);
for i=1:h
    for j=1:w
        t1(i,j)=(gradient_profile_max-gradient_profile_ori1)*(A-min(input_image(i,j,:)));
        t2(i,j)=(gradient_profile_max-gradient_profile_ori1)*A-(min(input_image(i,j,:))-gradient_profile_ori1)*min(input_image(i,j,:));
        t(i,j)=t1(i,j)/t2(i,j);
    end
end
t=max(min(t,1),0);
figure;
imshow(t),title('Filtered Depth');


t0=0.1;
fog_removed=zeros(h,w,c);
for i=1:c
    for j=1:h
        for l=1:w
            fog_removed(j,l,i)=(input_image(j,l,i)-A)/max(t(j,l),t0)+A;
        end
    end
end

%image adpative gamma correction using imadjust function 
limits = stretchlim(fog_removed, 0.03);
img_adjusted = imadjust(fog_removed, limits, []);

imwrite(img_adjusted,'fog1.png');


% Display the results
figure,imshow(img_adjusted, [0,255]),title('Final image');
%figure,hist(img_adjusted,2),title('color measures frequency');

[MSE,PSNR,AD,SC,NK,MD,LMSE,NAE]=iq_measures(im2bw(input_image ), im2bw(img_adjusted))

em=mean2(im2bw(input_image ));
   mm=mean2(im2bw(img_adjusted));
   AMBE=abs(em-mm)

