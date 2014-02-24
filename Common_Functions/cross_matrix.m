function cm = cross_matrix(len)
%cm = cross_matrix(len)
%
% Generates a binary matrix of a cross with side length len.
%

cm = zeros(len,len);

if isodd(len)
    cr = ceil(len/2);
else
    cr = [len/2 len/2+1];
end

cm(:,cr) = 1;
cm(cr,:) = 1;
