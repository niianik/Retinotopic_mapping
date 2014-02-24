function ndegs = NormDeg(Degs, Rng)
%ndegs = NormDeg(Degs, Rng)
%
% Returns the normalized (0-359.9999 deg) angle of Degs.
% Rng denotes the range and it can only be 180 or 360 (default).
% If Rng is any other number, it will default to 360.

if nargin == 1 | (Rng ~= 360 & Rng ~= 180)
    Rng = 360;
end

ndegs = mod(Degs, Rng);

 