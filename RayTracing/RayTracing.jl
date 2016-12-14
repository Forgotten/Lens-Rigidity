## These are functions for Ray Tracing with just two basic shapes, Square and Circle.
## Mainly, just the square, because Circles are smooth and we have SmoothRayTracing.jl

function gaussianmetric(s,u)
# u(1) = x coordinate, u(2) = y coordinate,
# u(3) = x velocity, u(4) = y velocity.
# This has no bearing on the domain anyways!

    dH = zeros(4);
    # The positions:
    dH[1] = u[3].*exp(u[1].^2 + u[2].^2);
    dH[2] = u[4].*exp(u[1].^2 + u[2].^2);
    # The momenta:
    dH[3] = -(u[3].^2 + u[4].^2).*u[1].*exp(u[1].^2 + u[2].^2);
    dH[4] = -(u[3].^2 + u[4].^2).*u[2].*exp(u[1].^2 + u[2].^2);
    return dH

end

# Since the Hamiltonian is zero on these trajectories:
# If we instead use just 3 variables where the velocity is all encapsulated in
# just the direction, theta = u[3].

function gaussianmetrictheta(s,u)
  # u(1) = x coordinate, u(2) = y coordinate,
  # u(3) = x velocity, u(4) = y velocity.
  # This has no bearing on the domain anyways!
      dH = zeros(3);
      # The positions:
      dH[1] = cos(u[3]).*exp(u[1].^2/2 + u[2].^2/2);
      dH[2] = sin(u[3]).*exp(u[1].^2/2 + u[2].^2/2);
      # The momenta:
      dH[3] = (u[1].*sin(u[3]) - u[2].*cos(u[3])).*exp(u[1].^2/2 + u[2].^2/2);

      return dH;
end


#####################################################################


# function sgEventsFcn(s,u)
#   # Terminate ODE evolution when the position is outside of square.
#   value = max(0,1 - max(abs(u(1)), abs(u(2))));
#   isterminal = 1;
#   direction = -1;
#   return value,isterminal,direction;
# end


#####################################################################


function squaregaussianrelation(metric::Function,u0,ds)
  # This will take an initial condition and evolve the ODE for the scattering
  # relation. It will also make sure to get when it exits, and return the
  # exit position and velocity.
  # Maybe use a fixed step so that way it's more modulated?

  # options = odeset('Events',sgEventsFcn);   #### This is where we have problems??

  s,u = ode45(metric, u0, [0.0,ds]); #options);  # with official ODE.jl
  # ~,u = ODE.ode45(gaussianmetric, u0, [0.0,ds], stopevent = (s,u) -> (abs(u[1]) > 1 || abs(u[2]) > 1));
  # [~,u] = ode45(@gaussianmetric, [0,1], u0);  % for example
  # it should be kept adapative for the interval of length
  heaviside(x::AbstractFloat) = ifelse(x < 0, zero(x), ifelse(x > 0, one(x), oftype(x,0.5)));
  square(x,y) =  - heaviside(x.+1.0).*heaviside(-x.+1.0).*heaviside(-y.+1.0).*heaviside(y.+1.0);

  k = find(x -> ( square(x[1],x[2]) >= -eps() ), u[2:end]);
  kshift = 0;

  scaling = max(ds,1/ds);
  maxiter = 1;

  while isempty(k) && maxiter < 1000*scaling ## In case of trapped rays
    u0 = u[end];
    sadd,uadd = ode45(metric,u0,[0.0,ds]);
    k = find(x -> ( square(x[1],x[2]) >= -eps() ), uadd[2:end]);
    sadd = sadd + s[end];

    kshift = length(u);
    s = append!(s,sadd);
    u = append!(u,uadd);
    # k = find(x -> ( square(x[1],x[2]) >= -eps() ), u[2:end]);
    maxiter = maxiter + 1;
end

if isempty(k)
  k = length(u);
else
  k = k[1] + 1 + kshift;
end

  if maxiter >= 1000*scaling   # Suspect trapped rays.
    for k = 1:length(uf)
      uf[k]=Inf;
    end
    return append!(uf,Inf);
  end


  # Construct interpolant:
  u1 = u[k-1]; u2 = u[k];
  s1 = s[k-1][1]; s2 = s[k][1]; spread = s2-s1; sout = s1+0.5*spread;

  if abs(u2[1]-u1[1]) <= 1e-4 && abs(u2[2]-u1[2]) <= 1e-4    # Then we are basically fine....take an average.
    uf = (u2 + u1)./2;
    return append!(uf,sout);
  end

  # u1 = u[end-1]; u2 = uf;
  # s1 = s[end-1][1]; s2 = s[end][1]; sf = s2-s1;

  # Need more data points (specifically 5) for 4th order:
  dt = spread/4.0;
  tspan = 0:dt:spread;
  # sp,up = ODE.ode45(gaussianmetric,u1,tspan);
  s,u = ode45(metric,u1,tspan; points=:specified);    # is still being adaptive???
  up = u[1:5]; sp = s[1:5] + s1;
  up[end] = u2; sp[end] = s2;
  # Interpolate positions:
  xp = map( v -> v[1], up);
  xI = polyfit(sp, xp);
  yp = map( v-> v[2], up);
  yI = polyfit(sp, yp);

  uf = u2; # Need to use for corner cases, if both |x|,|y| > 1.

  # Because it's not root finding the exit point:
  if abs(uf[1]) >= 1  # x-exit
    dom = xI - sign(u2[1]);
    dxI = polyder(xI);
    sout = newtonbisection(dom, dxI, s1, s2, 1e-5);
    uf[1] = xI(sout); uf[2] = yI(sout);
  end


  if abs(uf[2]) >= 1  # Also to account for if y exits before x.
    dom = yI - sign(uf[2]);
    dyI = polyder(yI);
    sout = newtonbisection(dom, dyI, s1, s2, 1e-5);
    uf[1] = xI(sout); uf[2] = yI(sout);
  end

  # Interpolate velocity:
  for k = 1:length(uf)-2
    vp = map( t -> t[k+2], up);
    v = polyfit(sp,vp);
    uf[k+2] = v(sout);
  end

  return append!(uf,sout);

end



###############################################################


function SGscatteringrelation(thetaTF,metric,Nedge, Nangle, ds)
# Gather the exit data for the incidence data along the
# West(left),North(top),East(right),South(bottom) edges.

dl = 2/Nedge;
dphi = pi/Nangle;
uW = Array{Array}((Nedge-1),(Nangle-1));
uN = Array{Array}((Nedge-1),(Nangle-1));
uS = Array{Array}((Nedge-1),(Nangle-1));
uE = Array{Array}((Nedge-1),(Nangle-1));
# For the cells, each row is a point on the boundary edge and each collumn is
# an angle of incidence.
if thetaTF == false
  for i = 1:Nedge-1
      ds = dl*2*i*(Nedge-i)/Nedge;   # For bad points near corners.
      for j = 1:Nangle-1
          u0 = [-1; 1-i*dl; cos(j*dphi - pi/2); sin(j*dphi - pi/2)];   # Only for left edge!
          uW[i,j] = squaregaussianrelation(metric,u0,ds);
          u0 = [-1 + i*dl; -1; cos(j*dphi); sin(j*dphi)];   # Only for bottom edge!
          uS[i,j] = squaregaussianrelation(metric,u0,ds);
          u0 = [1; -1+i*dl; cos(j*dphi + pi/2); sin(j*dphi + pi/2)];   # Only for right edge!
          uE[i,j]= squaregaussianrelation(metric,u0,ds);
          u0 = [1 - i*dl; 1; cos(-j*dphi); sin(-j*dphi)];   # Only for top edge!
          uN[i,j] = squaregaussianrelation(metric,u0,ds);
      end
  end
end

if thetaTF == true
  for i = 1:Nedge-1
      ds = dl*2*i*(Nedge-i)/Nedge;   # For bad points near corners.
      for j = 1:Nangle-1
          u0 = [-1;1-i*dl;j*dphi-pi/2];   # 3-vars Left
          uW[i,j] = squaregaussianrelation(metric,u0,ds);
          u0 = [-1+i*dl;-1;j*dphi];   # 3-vars Bottom
          uS[i,j] = squaregaussianrelation(metric,u0,ds);
          u0 = [1;-1+i*dl;j*dphi+pi/2];   # 3-vars Right
          uE[i,j]= squaregaussianrelation(metric,u0,ds);
          u0 = [1-i*dl;1;-j*dphi];   # 3-vars Top
          uN[i,j] = squaregaussianrelation(metric,u0,ds);
      end
  end
end

return uW, uS, uE, uN;

end


#####################################################################


function circlegaussianrelation(u0,ds)
# This will take an initial condition and evolve the ODE for the scattering
# relation. It will also make sure to get when it exits, and return the
# exit position and velocity.
# Maybe use a fixed step so that way it's more modulated?

# options = odeset('Events',sgEventsFcn);   #### This is where we have problems??

# s,u = ODE.ode45(gaussianmetric, u0, [0.0,ds]);  # Legacy ODE
s,u = ode45(gaussianmetric, u0, [0.0,ds]);
k = find( x -> x[1]^2 + x[2]^2 > 1, u[2:end]);  # So we don't get the starting pt.

# s,u = ODE.ode45(gaussianmetric,u0,[0.0,ds],stopevent = (s,u) -> ( u[1]^2 + u[2]^2 > 1) );
# uf = u[end];

# it should be kept adapative for the interval of length

while isempty(k)
# while uf[1]^2 + uf[2]^2 < 1
  uf = u[end];
  # s,u = ODE.ode45(gaussianmetric,uf,[0.0,ds]);
  s,u = ode45(gaussianmetric, uf, [0.0,ds]);
  k = find( x -> x[1]^2 + x[2]^2 > 1, u[2:end]);
  #s,u = ODE.ode45(gaussianmetric,uf,[0.0,ds],stopevent = (s,u) -> ( u[1]^2 + u[2]^2 > 1) );
  #uf = u[end];
end

# Using the last point inside and oustide, create a 4th order interpolant:
k = k[1] + 1; # because it's skewed in the find!
u1 = u[k-1]; u2 = u[k];
s1 = s[k-1][1]; s2 = s[k][1]; spread = s2-s1;

# u1 = u[end-1]; u2 = uf;
# s1 = s[end-1][1]; s2 = s[end][1]; spread = s2-s1;

# Need more data points (specifically 5) for 4th order:
dt = spread/4.0;
tspan = 0:dt:spread;
# sp,up = ODE.ode45(gaussianmetric,u1,tspan);
s,u = ode45(gaussianmetric,u1,tspan);    # is still just adaptive???
up = u[1:5]; sp = s[1:5] + s1;
up[end] = u2; sp[end] = s2;
xp = map( v -> v[1], up); yp = map( v-> v[2], up);
xI = polyfit(sp,xp); yI = polyfit(sp, yp);
dxI = polyder(xI); dyI = polyder(yI);

# Now Newton solve applying these to the surface function:
domain(x,y) = x.^2. + y.^2. - 1;
domaingrad(x,y) = [2.*x, 2.*y];
sdomain(s) = domain(xI(s),yI(s));
sdomaingrad(s) = dot(domaingrad(xI(s),yI(s)) , [dxI(s), dyI(s)] );
sout = newtonbisection(sdomain, sdomaingrad, s1, s2, 1e-5);

vxp = map( v -> v[3], up); vyp = map( v-> v[4], up);
vxI = polyfit(sp,vxp); vyI = polyfit(sp, vyp);

# uf = [xI(sout), yI(sout), vxI(sout), vyI(sout)];
return [xI(sout), yI(sout), vxI(sout), vyI(sout)];

# # Because it is not rootfinding when terminating:
# uf[1] = uf[1]/sqrt(uf[1]^2 + uf[2]^2);
# uf[2] = uf[2]/sqrt(uf[1]^2 + uf[2]^2);
#
# # Normalize velocity for direction:
# uf[3] = uf[3]/sqrt(uf[3]^2 + uf[4]^2);
# uf[4] = uf[4]/sqrt(uf[3]^2 + uf[4]^2);

# return uf;

end

# Prior to using Events:

# k = find(x -> x[1]^2 + x[2]^2 > 1, u[2:end]);
#
# if isempty(k)
#     u0 = u[end];
#     uf = circlegaussianrelation(u0,ds);
#     return uf;
# end
#
# if !isempty(k)
#    k = k[1] + 1;
# end
#
# uf = u[k];
# dy = u[k][2][1]-u[k-1][2][1];    # Be careful that they
# dx = u[k][1][1]-u[k-1][1][1];
# m = dy/dx;
# # Can we just use slope m (or, dy and dx) for the directions/velocities?
#
# y(x) = u[k-1][2][1] + m*(x-u[k-1][1][1]);
# f(x) = x^2 + y(x)^2 - 1;   # We don't necessarily need the square root.
# df(x) = 2.0.*x + 2.0.*y(x)*m;
# a=u[k-1][1][1];
# b=u[k][1][1];
#
# uf[1] = newtonbisection(f,df,a,b,10^(-5.0));
# uf[2] = y(uf[1]);
# ## Newton Solve for f(x) = 0 !!!
#
# uf[3] = uf[3]/sqrt(uf[3]^2 + uf[4]^2);
# uf[4] = uf[4]/sqrt(uf[3]^2 + uf[4]^2);
#
# return uf;
#
# end


###############################################################


function CGscatteringrelation(Nrotate, Nangle)
  # Maybe will take out the ds ???
# Gather the exit data for the incidence data along the
# West(left),North(top),East(right),South(bottom) edges.

ds=1;
dtheta = 2*pi/Nrotate;
dphi = pi/Nangle;
uTotExit = Array{Any}(Nrotate - 1, Nangle - 1);
# For the cells, each row is a point on the boundary edge and each collumn is
# an angle of incidence.


for i = 1:Nrotate-1
    for j = 1:Nangle-1
      ds = 2*j*dphi*(Nangle-j)/Nangle;
      u0 = [cos(i*dtheta), sin(i*dtheta), cos(i*dtheta + pi/2 + j*dphi), sin(i*dtheta + pi/2 + j*dphi)];
      uTotExit[i,j] = circlegaussianrelation(u0,ds);
    end
end

return uTotExit;

end


#################################################


function newtonbisection(f,df,a::Float64,b::Float64,tol)
maxiter = 100;
p=a; iter = 1;
while abs(f(p)[1]) > tol && iter < 100
  iter = iter + 1;
   p = p - f(p)/df(p);
   if p>b
       p=(a+b)/2; end;
   if p<a
       p=(a+b)/2; end;
   if f(p)*f(b)<0
       a=p;
   else
       b=p;
   end
end

return p;

end
