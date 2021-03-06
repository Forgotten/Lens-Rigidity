%% Scripts to run ode45 for ray tracing
% This is just for the square case and the metric g is a Gaussian. 
% These are just notes / scratch work primarily. 

% First define the Hamiltonian system:

% function dH = gaussianmetric(s,u)
% % u(1) = x coordinate, u(2) = y coordinate, 
% % u(3) = x velocity, u(4) = y velocity.
%     dH = zeros(4,1);
%     % The positions:
%     dH(1) = u(3).*exp(u(1).^2 + u(2).^2);
%     dH(2) = u(4).*exp(u(1).^2 + u(2).^2);
%     % The momenta: 
%     dH(3) = (u(3).^2 + u(4).^2).*u(1).*exp(u(1).^2 + u(2).^2);
%     dH(4) = (u(3).^2 + u(4).^2).*u(2).*exp(u(1).^2 + u(2).^2);
% end

%% Checking the ODE evolution is fine and iterating.
tic;
Nrotate = 2^5;   % number of partitions of rotation angle 0 to 2*pi.
Nangle = 2^5;   % number of partitions of angle.
dphi = pi/Nangle;   % This needs to be taken better care of
dtheta = 2*pi/Nrotate; 
% Two loops over n,N
% Can switch the order of for loops to see the change in ray traces with 
% entry position or entry angle graphically.
%%
% To terminate when x^2 + y^2 >= 1
options = odeset('Events',@cgEventsFcn); 
% Here, the events function was defined as:
% function [value,isterminal,direction] = sgEventsFcn(s,u)
% % Terminate ODE evolution when the position is outside of square.
% value = max(0,1 - sqrt(u(1)^2 + u(2)^2));
% isterminal = 1;
% direction = -1;
% end
%%
for i = 1:Nrotate-1
    clf
    for j = 1:Nangle-1
        u0 = [cos(i*dtheta), sin(i*dtheta), cos(i*dtheta + pi/2 + j*dphi), sin(i*dtheta + pi/2 + j*dphi)]; 
        [s,u,~,ue] = ode45(@gaussianmetric, [0,1], u0, options);
        % The arclength interval of ODE evolution has to be small enough
        % for the event to trigger sometimes, perhaps relate with dtheta? 
        
        % Noting how some rays don't make it out yet
        plot(u(:,1), u(:,2)); 
        if j==1
            axis([-2 2 -2 2]);
            xlabel('x position'); ylabel('y position');
            theta = 0:0.1:2*pi+0.1;
            x = cos(theta); y = sin(theta);
            hold on
            plot(x,y);
        end
    end
    pause(0.001);
end
toc;
% The last spread of angles is displayed

%% Scattering Relation, Exit Data. 
% Then search for when it 1st leaves the box somehow. 
% Uses squaregaussianrelation.m --> if working correctly, then use to
% get all the data with SGscatteringrelation.m 

% Two velocity interpolations used in squaregaussianrelation.m , 
% Could subtract two methods to see how their accuracy is w.r.t. each other

tic;
ds = dtheta*2^3;  % Or can make it smaller/larger?
uExit = zeros((Nrotate-1),(Nangle-1),4); 
% The cell of all exit-pos/vel for each given incidence pos/angle. 
% For the cells, each row is a point on the boundary and each collumn is
% the angle of incidence. So,
% The 1st entry ~ location on the edge. 2nd entry ~ angle of incidence.

for i = 1:Nrotate-1
    for j = 1:Nangle-1
        ds = 4*j*dphi*(Nangle-j)/Nangle;
        u0 = [cos(i*dtheta), sin(i*dtheta), cos(i*dtheta + pi/2 + j*dphi), sin(i*dtheta + pi/2 + j*dphi)]; 
        uExit(i,j,:) = circlegaussianrelation(u0,ds);
    end
end

%%
% To check qualitatively with the plot above:
disp(uExit(end,:,:))
toc;
% Be careful if we wanted to switch the order of for loops
% It looked consistent with all 4 sides. 
%% Entire scattering relation
% Use: (Takes a while to compute)
tic;
uTotExit = CGscatteringrelation(Nrotate, Nangle);

% To check with prior notes I guess:
disp(uTotExit(end,:,:))
%%
% To get the components, I guess just do a for loop, e.g. for x:
xexit = uTotExit(:,:,1); yexit = uTotExit(:,:,2);
disp(xexit(end,:) - uTotExit(end,:,1))
%%
% Check boundary: 
M = xexit.^2 + yexit.^2 - 1;
disp(norm(M(:),Inf))
toc;

