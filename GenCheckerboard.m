width = 800;    % Define here the height of the screen 

addpath('Common_Functions');
Checkerboard = RadialCheckerBoard([width/2 20], [-180 180], [7 5]);
save('Checkerboard', 'Checkerboard');