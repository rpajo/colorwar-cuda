srcFiles = dir('izhodi/*.bmp');
barve = textread('barve.txt');
for i = 1 : length(srcFiles)
    figure(1)
    filename = strcat('izhodi/',srcFiles(i).name);
    I = imread(filename);
    imshow(I);
    pause(0.2)
    figure(2)
    plot(barve(1:i, 1), 'r');
    hold on
    plot(barve(1:i, 2), 'g');
    plot(barve(1:i, 3), 'b');
    %figure, imshow(I);
end
