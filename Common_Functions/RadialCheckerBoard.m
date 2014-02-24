function img = RadialCheckerBoard(radius, sector, chsz, propel)
%img = RadialCheckerBoard(radius, sector, chsz{, propel})
% Returns a bitmap image of a radial checkerboard pattern.
% The image is a square of 2*OuterRadius+1 pixels.
%
% Parameters of wedge:
%   radius :    eccentricity of radii in pixels = [outer, inner] 
%   sector :    polar angles in degrees = [start, end] from -180 to 180
%   chsz :      size of checks in log factors & degrees respectively = [eccentricity, angle]
%   propel :    Optional, if defined there are two wedges
%

checkerboard = [0 255; 255 0];
img = ones(2*radius(1), 2*radius(1)) * 127;

for x = -radius : radius 
    for y = -radius : radius 
        [th r] = cart2pol(x,y); 
        th = th * 180/pi;
        if th >= sector(1) && th < sector(2) && r < radius(1) && r > radius(2)
            img(y+radius(1)+1,x+radius(1)+1) = checkerboard(mod(floor(log(r)*chsz(1)),2) + 1, mod(floor((th + sector(1))/chsz(2)),2) + 1); 
        end
    end
end

img = flipud(img);

if nargin > 3
    rotimg = flipud(fliplr(img));
    non_grey_pixels = find(rotimg ~= 127);
    img(non_grey_pixels) = rotimg(non_grey_pixels);
end

img = uint8(img);