


struct CartesianOrbit{T<:Number} <: AbstractOrbit{T}
    # Note: these position and velocity values are in *barycentric* coordinates
    x::T    # AU (increasing to the left)
    y::T    # AU (increasing upwards)
    z::T    # AU (increasing away)
    vx::T   # AU/yr
    vy::T   # AU/yr
    vz::T   # AU/yr
    M::T    # Host mass (solar masses)


    # Orbital properties
    a::T
    e::T
    i::T
    ω::T
    Ω::T
    tp::T

    # Physical constants
    T::T
    n::T
    ν_fact::T
    p::T

    # Geometric factors
    cosi::T
    sini::T
    cosΩ::T
    sinΩ::T
    ecosω::T
    esinω::T
    cosi_cosΩ::T
    cosi_sinΩ::T

    # Semiamplitudes
    J::T
    K::T
    A::T
    function CartesianOrbit(x, y, z, vx, vy, vz, M, tref=0; tol=1e-8)
        # tref is the epoch at which these values are provided

        # This code was adapted from a combination of:
        # https://github.com/spencerw/keplerorbit/blob/master/KeplerOrbit/KeplerOrbit.py (MIT license)
        # https://github.com/esa/pykep/blob/403a7dfe8ed3ff19b43bcbd6e6856de7f820cf55/src/third_party/cspice/oscelt.c#L429 (public domain)
        # https://github.com/poliastro/poliastro/blob/21fd7719e89a7d22b4eac63141a60a7f1b01768c/src/poliastro/core/elements.py#L279 (MIT license)

        if M isa Integer
            M = float(M)
        end
        x, y, z, vx, vy, vz, M, tref  = promote(x, y, z, vx, vy, vz, M, tref)
        T = typeof(x)
 
        # Unit vectors
        i⃗ = @SVector(T[1.0, 0.0, 0.0])
        j⃗ = @SVector(T[0.0, 1.0, 0.0])
        k⃗ = @SVector(T[0.0, 0.0, 1.0])

        # Position vector
        r⃗ = @SVector([ x,  y, z])
        r = norm(r⃗)
        if r == 0
            error("0 position vector")
        end

        # Velocity vector
        v⃗ = @SVector([vx, vy, vz]) ./ 2π # TODO: track this down!
        v = norm(v⃗)
        if r == 0
            error("0 velocity vector")
        end

        # Angular momentum vector
        h⃗ = r⃗ × v⃗
        h = norm(h⃗)
        if h == 0
            error("velocity and position vectors are parallel (degenerate case)")
        end

        # Eccentricity vector
        tmp⃗ = v⃗ × h⃗
        e⃗ = tmp⃗ / M - r⃗ / r
        e = norm(e⃗)
        # Equivalent:
        # e⃗ = ((v⃗ ⋅ v⃗ - M / r) * r⃗ - (r⃗ ⋅ v⃗) * v⃗) / M
        # e = norm(e⃗)

        n⃗ = k⃗ × h⃗
        n = norm(n⃗)

        oneminusesq = (1 - e^2)

        # Inclination
        i = π - acos((k⃗ ⋅ h⃗) / h)

        if e < 1
            ν_fact = √((1+e)/(1-e)) # true anomaly prefactor
        else
            ν_fact = √((1+e)/(e-1)) # true anomaly prefactor
        end

        circular = e < tol
        equatorial = abs(i) < tol


        if equatorial && !circular
            error("TODO 1")
        elseif !equatorial && circular
            # e = oftype(e, 0)
            # e⃗ = e⃗ * oftype(e, 0)
            error("TODO 2")
        elseif equatorial && circu
            # e = oftype(e, 0)
            # e⃗ = e⃗ * oftype(e, 0)lar
            error("TODO 3")
        else
            p = h^2 / M 
            a = p / (1 - (e^2))
            # elliptical or hyperbolic
            if a > 0
                println("elliptical")
                e_se = (r⃗⋅v⃗) / sqrt(M*a)
                e_ce = r*v^2 / M - 1
                ν = 2atan(ν_fact*tan(atan(e_se, e_ce) / 2))
                a = p/oneminusesq
                periodyrs = √(a^3/M)
                period = periodyrs * year2day # period [days]
                meanmotion = 2π/periodyrs # mean motion
            else
                println("not elliptical")
                e_sh = (r⃗ ⋅ v⃗) / sqrt(-M*a)
                e_ch = r * v^2 / M - 1
                F2ν(F) = 2atan(ν_fact*tanh(F/2))
                ν = F2ν(log((e_ch + e_sh) / (e_ch - e_sh)) / 2)
                period = Inf
                meanmotion = 2π * √(M/-a^3) # mean motion
            end
            px = r⃗ ⋅ n⃗
            py = (r⃗ ⋅ (h⃗ × n⃗)) / h
            ω = rem2pi(atan(py, px) - ν, RoundNearest)
            if n⃗[2] >= 0
                Ω = 3pi/2 - acos(n⃗[1]/n);
            else
                Ω = acos(n⃗[1]/n)  -pi/2 
            end
        end
        Ω += pi

        # Ω = rem2pi(Ω, RoundNearest)
        # ω += pi
        # Ω = 2pi - Ω
        # @show Ω ω

      
        # if n⃗[2] >= 0
        #     Ω = acos(n⃗[1]/N);
        # else
        #     Ω = 2π - acos(n⃗[1]/N);
        # end
        # Ω = pi/2 - Ω + pi

 


        # # # Due to round off, we can sometimes end up just a tiny bit greater than 1.
        # # # In that case, apply a threshold of 1.
        # if i != 0
            # arg = (i⃗ ⋅ n⃗) / n
            # arg = cleanroundoff(arg)
            # Ω = 2asin(arg)
            # if n⃗ ⋅ j⃗ < 0
            #     Ω = 2π - Ω
            # elseif 0 <= n⃗ ⋅ j⃗ 
            #     Ω =  Ω - π
            # end
            # # Ω = rem2pi(Ω, RoundDown)
            # Ω = rem(Ω, pi, RoundDown)
        # else
        #     Ω = zero(i)
        # end

        # # if e == 0
        # #     @error "e == exactly 0 not yet implemented correctly"
        # #     ω = 0.0
        # # else
            # if i != 0
            #     arg = cleanroundoff((n⃗ ⋅ e⃗) / (n * e))
            #     ω = acos(arg)
            # else
            #     ω = 3π/2 - atan(e⃗[2] / e, e⃗[1] / e)
            # end
            # if e⃗ ⋅ k⃗ < 0
            #     ω = π - ω
            # elseif 0 <= e⃗ ⋅ k⃗
            #     ω =  ω - π
            # end
            # ω = rem2pi(ω, RoundNearest)
            # ω += pi
        # end

        # @show Ω ω


        # arg3 = cleanroundoff((e⃗ ⋅ r⃗) / (e * r))
        # if e > 0
        #     θ = acos(arg3)
        # else
        #     # work around 0 eccentricty case.
        #     # TODO: there should be a more elegant numerical recipe for this
        #     θ = zero(eltype(e))
        # end
        # if r⃗ ⋅ v⃗ > 0.
        #     θ = 2pi - θ
        # end

        # arg4 = (e + cos(θ)) / (1 + e * cos(θ))
        # @show arg4
        # EA = acos(arg4)
        # @show EA
        # if π < θ < 2π
        #     EA = 2π - EA
        # end
        # MA = EA - e * sin(EA)


        # oneminusesq = (1 - e^2)
        # p = a*oneminusesq # semi-latus rectum [AU]

        # if e < 1
        #     periodyrs = √(a^3/M)
        #     period = periodyrs * year2day # period [days]
        #     n = 2π/periodyrs # mean motion
        # else
        #     period = Inf
        #     # TODO: Need to confirm where this 2pi is coming from 
        #     n = 2π * √(M/-a^3) # mean motion
        #     # n = √(M/-a^3) # mean motion
        # end

        # Remaining calculation: determine tp
        # Need mean anomaly
        if e < 1
            EA = 2atan(tan(ν/2)/ν_fact)
            MA = EA - e*sin(EA)
        else
            EA = 2atanh(tan(ν/2)/ν_fact)
            MA = e*sinh(EA) -EA

        end
        tp = -MA / meanmotion * PlanetOrbits.year2day + tref

        # Geometric factors involving rotation angles
        sini, cosi = sincos(i)
        sinω, cosω = sincos(ω)
        sinΩ, cosΩ = sincos(Ω)
        ecosω = e * cosω
        esinω = e * sinω
        cosi_cosΩ = cosi * cosΩ
        cosi_sinΩ = cosi * sinΩ

        if e < 1
            J = ((2π * a) / periodyrs) / √oneminusesq # horizontal velocity semiamplitude [AU/year]
            K = J * au2m * sec2year * sini # radial velocity semiamplitude [m/s]
            A = ((4π^2 * a) / periodyrs^2) / oneminusesq^2 # horizontal acceleration semiamplitude [AU/year^2]
        else
            @warn "velocity and acceleration not implemented for ecc >= 1 yet"
            J = K = A = 0.0
        end

        orbit = new{typeof(M)}(
            # Passed parameters that define the elements
            x, y, z, vx, vy, vz, M,
            # Converted campbell elements
            a, e, i, ω, Ω, tp,
            # Cached calcuations
            period, meanmotion, ν_fact, p,
            # Geometric factors
            cosi, sini, cosΩ, sinΩ, ecosω, esinω, cosi_cosΩ, cosi_sinΩ,
            # Semiamplitudes
            J, K, A
        )
        return orbit
    end
end
CartesianOrbit(;x, y, z, vx, vy, vz, M, tref=0, kwargs...) = CartesianOrbit(x, y, z, vx, vy, vz, M, tref)

function cleanroundoff(arg)
    # Due to round off, we can sometimes end up just a tiny bit greater than 1 or less than -1.
    # In that case, apply a threshold of 1.
    if 1 < abs(arg) < 1+3eps()
        arg = one(arg)
    elseif -1-3eps() < abs(arg) < -1
        arg = -one(arg)
    end
    return arg
end

period(o::CartesianOrbit) = o.T
meanmotion(o::CartesianOrbit) = o.n
eccentricity(o::CartesianOrbit) = o.e
totalmass(o::CartesianOrbit) = o.M
inclination(o::CartesianOrbit) = o.i
semimajoraxis(o::CartesianOrbit) = o.a
function _trueanom_from_eccanom(o::CartesianOrbit, EA)
    if o.e < 1
        ν = 2*atan(o.ν_fact*tan(EA/2))
    else
        # true anomaly prefactor changed in constructor if hyperbolic
        ν = 2*atan(o.ν_fact*tanh(EA/2))
    end
    return ν
end
periastron(elem::CartesianOrbit) = elem.tp
semiamplitude(elem::CartesianOrbit) = elem.K

"""
Represents a `CartesianOrbit` evaluated to some position.
"""
struct OrbitSolutionCartesian{T<:Number,TEl<:CartesianOrbit} <: AbstractOrbitSolution
    elem::TEl
    ν::T
    EA::T
    sinν_ω::T
    cosν_ω::T
    ecosν::T
    r::T
    t::T
    function OrbitSolutionCartesian(elem, ν, EA, sinν_ω, cosν_ω, ecosν, r, t)
        promoted = promote(ν, EA, sinν_ω, cosν_ω, ecosν, r, t)
        return new{eltype(promoted),typeof(elem)}(elem, promoted...)
    end
end
export CartesianOrbit
soltime(os::OrbitSolutionCartesian) = os.t

# Solve orbit to a new cartesian position given true anomaly
function orbitsolve_ν(elem::CartesianOrbit, ν, EA=2atan(tan(ν / 2) / elem.ν_fact), t=_time_from_EA(elem, EA))
    sinν_ω, cosν_ω = sincos(elem.ω + ν)
    ecosν = elem.e * cos(ν)
    r = elem.p / (1 + ecosν)
    return OrbitSolutionCartesian(elem, ν, EA, sinν_ω, cosν_ω, ecosν, r, t)
end

# TODO: we can accelerate this since we already know some parameters
"""
Convert an existing orbit object to a CartesianOrbit. 
"""
function CartesianOrbit(os::AbstractOrbitSolution)
    x = PlanetOrbits.posx(os)
    y = PlanetOrbits.posy(os)
    z = PlanetOrbits.posz(os)
    vx = PlanetOrbits.velx(os)
    vy = PlanetOrbits.vely(os)
    vz = PlanetOrbits.velz(os)
    return CartesianOrbit(
        x,
        y,
        z,
        vx,
        vy,
        vz,
        totalmass(os.elem),
        soltime(os)
    )
end




#=
o = orbit(a=1.0,i=0,ω=π/2,e=0.5,Ω=0,M=1,plx=100.,τ=0.0)

##
x  = -1.05
y  = 3.782338790704024e-16
z  = -2.5048146051777413e-17
vx = -3.490253699036788e-16 * 2pi
vy = -0.9464377445249709 * 2pi
vz = 0.09496052074620637 * 2pi
oc = CartesianOrbit(x,y,z,vx,vy,vz,1,0)

sc = orbitsolve(oc, 0)
x  = PlanetOrbits.posx(sc)
y  = PlanetOrbits.posy(sc)
z  = PlanetOrbits.posz(sc)
vx = PlanetOrbits.velx(sc)
vy = PlanetOrbits.vely(sc)
vz = PlanetOrbits.velz(sc)
oc2= CartesianOrbit(x,y,z,vx,vy,vz,1,0)
plot(orbitsolve(oc,0));plot!(orbitsolve(oc2,0))
# i appears to be going backwards


o = orbit(
    a = 1,
    i = π/4,
    Ω = 0.001,
    ω = 0.001,
    e = 0.5,
    τ = 0.5,
    M = 1,
    tref=0
)
t = 0
oc3 = CartesianOrbit(orbitsolve(o,t))
oc4 = CartesianOrbit(orbitsolve(oc3,t))
oc5 = CartesianOrbit(orbitsolve(oc4,t))
o.ω, oc3.ω, oc4.ω,oc5.ω
o.Ω, oc3.Ω, oc4.Ω,oc5.Ω
o.i, oc3.i, oc4.i,oc5.i
o.τ, oc3.τ, oc4.τ,oc5.τ
meananom(o,t), meananom(oc3,t), meananom(oc4,t),meananom(oc5,t)

plot(orbitsolve(o,t),label="o", lw=2, ls=:dash, color=1)
plot!(orbitsolve(oc3,t), label="oc3", color=2)
plot!(orbitsolve(oc4,t), label="oc4", color=3)
plot!(orbitsolve(oc5,t), label="oc5", color=4)

I think there are three things left:
* something about the dates / times stamping of CartesianOrbit is not making sense.
=#
