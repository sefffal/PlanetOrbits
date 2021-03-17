"""
# DirectOrbits
A package for calculating orbits in the context of direct imaging.

"""
module DirectOrbits

using LinearAlgebra
# using CoordinateTransformations
using StaticArrays
using Roots # For solving for eccentric anomaly
# import Dates
# import Base.inv
using Statistics: mean


const mas2rad = 4.8481368E-9
const rad2as = 206265
const pc2au = 206265
const au2m = 1.495978707e11
const year2days = 365.2422

# """
# Convert from (fraction of elements past periastron at MJD=0)
# to the time of periastron passage in MJD.
# P in years.
# τ [0,1]
# """
# function τ2t0(τ,P, τ_ref_epoch=58849) # modern convention as default
#     # t0 = τ_ref_epoch - τ*P*365.25

#     t0 = - τ_ref_epoch - τ
# end

abstract type AbstractElements end

"""
    Orbit(
        a=1.0, # semi-major axis, AU
        i=π/2, # inclination, radians
        e=0.1, # eccentricity
        τ=π/2, # fraction of elements past periastron passage at MJD=0,
        μ=1.0, # graviational parameter, solar masses
        ω=π/2, # argument of periapsis
        Ω=π/2, # longitude of the ascending node
        plx=10.1, # paralax in milliarcseconds. Defines the distance to the object
    )

Represents one object's Keplerian elementsal elements. Values can be specified
by keyword argument for convinience, or kep2cart for efficiency.

See also `KeplerianElementsDeg` for a convinience constructor accepting
units of degrees instead of radians.
"""
struct KeplerianElements{T<:Number} <: AbstractElements

    # Orbital properties
    a::T
    i::T
    e::T
    τ::T
    μ::T
    ω::T
    Ω::T
    plx::T

    # Cached constants for these elements
    dist::T
    T::T
    n::T
    ν_fact::T
    cos_Ω::T
    sin_Ω::T
    cos_i::T

    # Inner constructor to inforce invariants and pre-calculate a few
    # constants for these elements.
    function KeplerianElements(a, i, e, τ, μ, ω, Ω, plx)


        # Enforce invariants on user parameters
        a = max(a, zero(a))
        e = max(zero(e), min(e, one(e)))
        μ = max(μ, zero(μ))
        plx = max(plx, zero(plx))
        # Pre-calculate some factors that will be re-used when calculating kep2cart at any time
        # Distance in AU
        dist = 1/(plx/1000) * pc2au
        # Compute period (days)
        period = √(a^3/μ) * year2days
        # Mean motion
        n = 2π/√(a^3/μ)
        # Factor in calculating the true anomaly
        ν_fact = √((1+e)/(1-e))

        T = promote_type(
            typeof(a),
            typeof(i),
            typeof(e),
            typeof(τ),
            typeof(μ),
            typeof(ω),
            typeof(Ω),
            typeof(plx),
        )
        # The user might pass in integers, but it makes no sense to do these
        # calculations on integers. Assume they mean to use floats.
        if T <: Integer
            T = promote_type(T, Float64)
        end
        new{T}(
            # Passed parameters that define the elements
            a,
            i,
            e,
            τ,
            μ,
            ω,
            Ω,
            plx,
            # Cached calcuations
            dist,            
            period,
            n,
            ν_fact,
            # Geometric factors
            cos(Ω),
            sin(Ω),
            cos(i),
        )
    end
end
# Allow arguments to be specified by keyword.
KeplerianElements(;a, i, e, τ, μ, ω, Ω, plx) = KeplerianElements(a, i, e, τ, μ, ω, Ω, plx)
export KeplerianElements

"""
    astuple(elements)

Return the parameters of a KeplerianElements value as a tuple.
"""
function astuple(elem::KeplerianElements)
    return (;elem.a,elem.i,elem.e,elem.τ,elem.μ,elem.ω,elem.Ω,elem.plx)
end

"""
    KeplerianElementsDeg(a, i, e, τ, μ, ω, Ω, plx)

A convinience function for constructing KeplerianElements where
`i`, `ω`, and `Ω` are provided in units of degrees instead of radians.
"""
KeplerianElementsDeg(a, i, e, τ, μ, ω, Ω, plx) = KeplerianElements(a, deg2rad(i), e, τ, μ, deg2rad(ω), deg2rad(Ω), plx)
KeplerianElementsDeg(;a, i, e, τ, μ, ω, Ω, plx) = KeplerianElementsDeg(a, i, e, τ, μ, ω, Ω, plx)
export KeplerianElementsDeg

function Orbit(args...; kwargs...)
    @warn "Orbit is deprecated in favour of KeplerianElements"
    return KeplerianElements(args...; kwrags...)
end
export Orbit

# Better printing
Base.show(io::IO, ::MIME"text/plain", elem::KeplerianElements) = print(
    io, """
        $(typeof(elem))
        ─────────────────────────
        a   [au ] = $(round(elem.a,sigdigits=3)) 
        i   [°  ] = $(round(rad2deg(elem.i),sigdigits=3))
        e         = $(round(elem.e,sigdigits=3))
        τ         = $(round(elem.τ,sigdigits=3))
        μ   [M⊙ ] = $(round(elem.μ,sigdigits=3)) 
        ω   [°  ] = $(round(rad2deg(elem.ω),sigdigits=3))
        Ω   [°  ] = $(round(rad2deg(elem.Ω),sigdigits=3))
        plx [mas] = $(round(elem.plx,sigdigits=3)) 
        ──────────────────────────
        period      [yrs ] : $(round(period(elem)/year2days,digits=1)) 
        distance    [pc  ] : $(round(distance(elem),digits=1)) 
        mean motion [°/yr] : $(round(rad2deg(meanmotion(elem)),sigdigits=3)) 
        ──────────────────────────
        """)
Base.show(io::IO, elem::KeplerianElements) = print(io,
    "KeplerianElements($(round(elem.a,sigdigits=3)), $(round(elem.i,sigdigits=3)), $(round(elem.e,sigdigits=3)), "*
    "$(round(elem.τ,sigdigits=3)), $(round(elem.μ,sigdigits=3)), $(round(elem.ω,sigdigits=3)), "*
    "$(round(elem.Ω,sigdigits=3)), $(round(elem.plx,sigdigits=3)))"
)


import Base: length, iterate
length(::AbstractElements) = 1
iterate(elem::AbstractElements) = (elem, nothing)
iterate(::AbstractElements, ::Nothing) = nothing


"""
    period(elem)

Period of an orbit in days.
"""
period(elem::KeplerianElements) = elem.T
export period

"""
    distance(elem)

Distance to the system in parsecs.
"""
distance(elem::KeplerianElements) = elem.dist/pc2au
export distance

"""
    meanmotion(elem)

Mean motion, radians per year.
"""
meanmotion(elem::KeplerianElements) = elem.n

"""
    kep2cart(elements, t)

Given an set of elementsal elements with a time `t` in days to get
a projected displacement x, y, and z in milliarcseconds.
X is increasing to the West, Y increasing to the North, and Z 
away from the observer.

See also: `projectedseparation`, `raoff`, `decoff`, and `losoff`.

In pathalogical cases solving for eccentric anomaly might fail.
This is very unlikely for any reasonable elements with e ≤ 1, but if using
this routine as part of an image distortion step (via e.g. CoordinateTransformations)
than this can occur near the origin. A warning will be generated
and the function will use the mean anomaly in place of the eccentric anomaly.
"""
function kep2cart(elem::KeplerianElements{T}, t, throw_ea=false) where T
    T2 = promote_type(T, typeof(t))
    

    # Compute mean anomaly
    # MA = elem.n * (t - 58849.0)/year2days - 2π*elem.τ
    # MA = elem.n * (t/365.25) - 2π*elem.τ

    # MA = elem.τ - elem.n * (t - 58849.0)/year2days 
    # MA = elem.τ - elem.n * t /year2days 
    # MA = elem.n * (t - 58849.0)/365.25 - 2π*elem.τ

    # MA = 2π*elem.τ - elem.n * (t - 58849.0)/year2days 
    # MA = elem.n * (58849.0 - t)/year2days - 2π*elem.τ


    MA = meanmotion(elem)/convert(T2, year2days) * (t - elem.τ)
    MA = rem2pi(MA, RoundDown)

    # EA = eccentric_anomaly(elem.e, MA; throw_ea)
    EA = eccentric_anomaly(elem.e, MA)

    
    # Calculate true anomaly
    ν = convert(T2,2)*atan(elem.ν_fact*tan(EA/convert(T2,2)))

    # New elementsal radius.
    # This is the semi-major axis, modified by the eccentricity. Units of AO
    r = elem.a*(one(T2)-elem.e*cos(EA))

    # Necessary if we want to calculate RV
    # h = sqrt(elem.μ*elem.a*(1-elem.e^2))
    
    # Project back into Cartesian coordinates (AU).
    x = r*(elem.sin_Ω*cos(elem.ω+ν) + elem.cos_Ω*sin(elem.ω+ν)*elem.cos_i)
    y = r*(elem.cos_Ω*cos(elem.ω+ν) - elem.sin_Ω*sin(elem.ω+ν)*elem.cos_i)
    z = r*(sin(elem.i)*sin(elem.ω+ν))

    # coords_AU = SVector(x,y,z)
    # coords_AU = MVector(x,y,z)
    coords_AU = [x,y,z]
    dist_proj_rad = atan.(coords_AU, elem.dist)
    dist_proj_mas = dist_proj_rad .* convert(eltype(dist_proj_rad),rad2as*1e3) # radians -> mas

    return dist_proj_mas
end
export kep2cart


"""
    eccentric_anomaly(elem, MA)

From an elements and mean anomaly, calculate the eccentric anomaly
numerically (Kepler's equation).

In pathalogical cases solving for eccentric anomaly might fail.
This is unlikely for any reasonable elements, but if using this routine
as part of an image distortion step (via e.g. CoordinateTransformations)
than this can occur near the origin. A warning will be generated
and the function will return (0,0,0). Specifying `throw_ea=true`
turns that warning into an error.
"""
function eccentric_anomaly(e, MA)
    throw_ea = false

    # Numerically solve EA = MA + e * sin(EA) for EA, given MA and e.


    # Fast path for perfectly circular orbits
    if e == 0
        return MA
    end


    # if e ≥ 1
    #     if throw_ea
    #         error("Parabolic and hyperbolic orbits are not yet supported (e≥1)")
    #     else
    #         @warn "Parabolic and hyperbolic orbits are not yet supported (e≥1, e=$e)" maxlog=5
    #         return MA
    #     end
    # end

    # @show e MA


    # Solve for eccentric anomaly
    # The let-block is to capture the bindings of e and M1 directly (performance)
    f= let e = e, MA=MA
        @inline f(EA) = EA - MA - e*sin(EA)
    end

    # After experimentation, Roots finds the root the 
    # fastest / with least allocations using zeroth-order 
    # methods without derivatives. This was surprising.
    # Therefore, we only pass the ojective and no
    # derivatives even though they are trivial to provide.

    # For pathalogical cases, this may not converge.
    # In that case, throw a warning and send the point to the origin


    # For cases very close to one, use a method based on the bisection
    # method immediately
    if isapprox(e, 1, rtol=1e-3)
        try
            # This is a modification of the bisection method. It should be 
            # very very robust.
            EA = find_zero(f, (MA-1, MA+1), FalsePosition(), maxevals=100)
        catch err
            if typeof(err) <: InterruptException
                rethrow(err)
            end
            @warn "Solving for eccentric anomaly near 1 failed. Pass `throw_ea=true` to turn this into an error." e exception=err maxlog=5
            return MA
        end
    end

    # In general, on the other hand:
    local EA
    try
        # Our initial start point EA₀ begins at the mean anomaly.
        # This is a common prescription for fast convergence,
        # though there are more elaborate ways to get better values.
        EA₀ = MA
        # Begin the initial conditions differntly for highly eccentric orbits,
        # another common prescription.
        if e > 0.8
            EA₀ = oftype(MA, π)
        end
        # In benchmarking, the most consistently fast method for solving this root
        # is actually not Newton's method, but the default zeroth order method.
        # We bail out very quickly though if it is not converging (see below)
        EA = find_zero(f, EA₀, maxevals=150)
    catch err
        if typeof(err) <: InterruptException
            rethrow(err)
        end
        # If it fails to converge in some pathalogical case,
        # try a different root finding algorithm.
        # This is a modification of the bisection method. It should be 
        # very very robust.
        # TODO: there are precriptions on how to choose the initial 
        # upper and lower bounds that should be implemented here.
        try
            # EA = find_zero(f, (-2π, 2π), FalsePosition(), maxevals=100)
            EA = find_zero(f, (MA-1, MA+1), FalsePosition(), maxevals=100)
        catch err
            if typeof(err) <: InterruptException
                rethrow(err)
            end
            @warn "Solving for eccentric anomaly failed twice. Pass `throw_ea=true` to turn this into an error." e exception=err maxlog=5
            return MA
        end
    end
end

# Using implicit differentiation, the derivatives of eccentric anomaly
# have closed form solutions once the primal value is known. 
# By providing thoesehere, upstream  automatic differentiation libraries
# will be able to efficiently diff through Kepler's equation.
using ChainRulesCore
@scalar_rule eccentric_anomaly(e, MA) @setup(u = 1 - e*cos(Ω)) (sin(Ω) / u, 1 / u)


"""
    raoff(elements, t)

Get the offset from the central body in Right Ascention in
milliarcseconds at some time `t` in days.
"""
function raoff(elements::AbstractElements, t)
    return kep2cart(elements, t)[1]
end
export raoff

"""
    decoff(elements, t)

Get the offset from the central body in Declination in
milliarcseconds at some time `t` in days.
"""
function decoff(elements::AbstractElements, t)
    return kep2cart(elements, t)[2]
end
export decoff

"""
    losoff(elements, t)

Get the offset from the central body in the line of sight towards
the system at time `t` in days, also in milliarcseconds. Of course, we can't observe this
displacement, but we use the same units for consistency.
"""
function losoff(elements::AbstractElements, t)
    return kep2cart(elements, t)[3]
end
export losoff

"""
    projectedseparation(elements, t)

Projected separation in mas from the central body at time t (days).
"""
function projectedseparation(elements::AbstractElements, t)
    x,y,z = kep2cart(elements,t)
    return sqrt(x^2 + y^2 + z^2)
end
export projectedseparation

# TODO: take steps of equal projected distance instead of equal time.

using RecipesBase
@recipe function f(elem::AbstractElements)
    # ts = range(0, period(elem), step=year2days/12/4)
    ts = range(0, period(elem), length=100)
    # if length(ts) < 60
        # ts = range(0, period(elem), length=60)
    # end
    coords = kep2cart.(elem, ts)
    xs = [c[1] for c in coords]
    ys = [c[2] for c in coords]

    # We almost always want to see spatial coordinates with equal step sizes
    aspect_ratio --> 1
    # And we almost always want to reverse the RA coordinate to match how we
    # see it in the sky.
    xflip --> true

    return xs, ys
end

@recipe function f(elems::AbstractArray{<:AbstractElements})
    # ts = range(0, maximum(period.(elems)), step=year2days/12)
    # ts = range(0, maximum(period.(elems)), step=year2days/12/4)
    ts = range(0, maximum(period.(elems)), length=100)
    # if length(ts) < 60
        # ts = range(0, maximum(period.(elems)), length=60)
    # end
    coords = kep2cart.(elems, ts')
    xs = [c[1] for c in coords]'
    ys = [c[2] for c in coords]'

    # Treat as one long series interrupted by NaN
    xs = reduce(vcat, [[x; NaN] for x in eachcol(xs)])
    ys = reduce(vcat, [[y; NaN] for y in eachcol(ys)])

    # We almost always want to see spatial coordinates with equal step sizes
    aspect_ratio --> 1
    # And we almost always want to reverse the RA coordinate to match how we
    # see it in the sky.
    xflip --> true
    xguide --> "ΔRA - mas"
    yguide --> "ΔDEC - mas"

    seriesalpha --> 30/length(elems)


    return xs, ys
end

include("Fitting.jl")

end # module
