function [uW, uN, uE, uS] = SGscatteringrelation(Nedge, Nangle)
% Gather the exit data for the incidence data along the 
% West(left),North(top),East(right),South(bot) edges. 

dl = 2/Nedge;
dphi = pi/Nangle;
uW = cell((Nedge-1),(Nangle-1));
uN = cell((Nedge-1),(Nangle-1));
uS = cell((Nedge-1),(Nangle-1));
uE = cell((Nedge-1),(Nangle-1));
% For the cells, each row is a point on the boundary and each collumn is
% the angle of incidence. 

ds = 1;

for i = 1:Nedge-1
    for j = 1:Nangle-1
        u0 = [-1; 1-i*dl; cos(j*dphi - pi/2); sin(j*dphi - pi/2)];   % Only for left edge!
        uW{i,j} = squaregaussianrelation(u0,ds);
        u0 = [-1 + i*dl; -1; cos(j*dphi); sin(j*dphi)];   % Only for bottom edge!
        uS{i,j} = squaregaussianrelation(u0,ds);
        u0 = [1; -1+i*dl; cos(j*dphi + pi/2); sin(j*dphi + pi/2)];   % Only for right edge!
        uE{i,j} = squaregaussianrelation(u0,ds);
        u0 = [1 - i*dl; 1; cos(-j*dphi); sin(-j*dphi)];   % Only for top edge!
        uN{i,j} = squaregaussianrelation(u0,ds);
    end
end

end

% Prior stuff just for checking:

% % Now for the South (Bottom) Edge:
% for i = 1:Nedge-2
%     for j = 1:Nangle-2
%         u0 = [-1 + i*dl; -1; cos(j*dphi); sin(j*dphi)];   % Only for bottom edge!
%         uS{i,j} = squaregaussianrelation(u0,ds);
%     end
% end
% 
% % Now the East (Right) Edge:
% for i = 1:Nedge-2
%     for j = 1:Nangle-2
%         u0 = [1; -1+i*dl; cos(j*dphi + pi/2); sin(j*dphi + pi/2)];   % Only for right edge!
%         uE{i,j} = squaregaussianrelation(u0,ds);
%     end
% end
% 
% % The North (Top) Edge:
% for i = 1:Nedge-2
%     for j = 1:Nangle-2
%         u0 = [1 - i*dl; 1; cos(-j*dphi); sin(-j*dphi)];   % Only for top edge!
%         uN{i,j} = squaregaussianrelation(u0,ds);
%     end
% end
