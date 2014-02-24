function imgOut = InvertContrast(imgIn)
%imgOut = InvertContrast(imgIn)
%
% Inverts the contrast of a greyscale image.
%

imgIn = double(imgIn);
imgOut = abs(imgIn-255);
imgOut = uint8(imgOut);
