srcFiles = dir('izhodi/*.bmp');
barve = textread('barve.txt');
for i = 1 : length(srcFiles)
    figure(1)
    filename = strcat('izhodi/',srcFiles(i).name);
    I = imread(filename);
    imshow(I);
    %pause(0.001)
    figure(2)
    plot(barve(1:i, 1), 'r');
    title('Vojna barv'), xlabel('Stevilo iteracij'),ylabel('Vsebovanost barv')
    legend('Rdeca','Zelena','Modra','Oranzna','Location','northwest')
    hold on
    plot(barve(1:i, 2), 'g');
    plot(barve(1:i, 3), 'b');
    plot(barve(1:i, 4),'color',[1.0,0.687,0.387]);
    %figure, imshow(I);
end
