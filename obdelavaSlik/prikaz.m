srcFiles = dir('izhodi/*.bmp');
for i = 1 : length(srcFiles)
    filename = strcat('izhodi/',srcFiles(i).name);
    I = imread(filename);
    imshow(I);
    %figure, imshow(I);
end
