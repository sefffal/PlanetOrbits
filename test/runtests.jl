# ----------------------------------------------------------------------------------------------------------------------
# Imports
# ----------------------------------------------------------------------------------------------------------------------

using Test
using PlanetOrbits
using ForwardDiff
using FiniteDiff

# ----------------------------------------------------------------------------------------------------------------------
# Constants and Helper Functions
# ----------------------------------------------------------------------------------------------------------------------

# 10 steps per day for one year
one_year_range = 0.0:0.1:365.24
# Relative tolerance for certain tests
rtol = 1e-4
# Absolute tolerance for certain tests
atol = 1e-6

# ----------------------------------------------------------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------------------------------------------------------




## Close to an idealized face-on Earth with circular orbit at 1 pc 
# Due to IAU definitions, values don't match exactly
@testset "Earth, i = 0, e = 0, d = 1 pc" begin
    idealearth = orbit(
        a = 1.0,
        e = 0.0,
        i = 0.0,
        ω = 0.0,
        Ω = 0.0,
        tp = 0.0,
        M = 1.0,
        plx = 1000.0
    )

    # Test basic orbit properties
    @test period(idealearth) ≈ PlanetOrbits.year2day_julian rtol=rtol
    @test distance(idealearth) ≈ 1.0 rtol=rtol
    @test meanmotion(idealearth) ≈ 2π rtol=rtol
    @test periastron(idealearth) ≈ 0.0
    @test semiamplitude(idealearth) ≈ 0.0

    # Orbit solutions at quarters of the orbit
    oq1 = PlanetOrbits.orbitsolve_ν(idealearth, 0.0)
    oq2 = PlanetOrbits.orbitsolve_ν(idealearth, π/2)
    oq3 = PlanetOrbits.orbitsolve_ν(idealearth, π)
    oq4 = PlanetOrbits.orbitsolve_ν(idealearth, 3π/2)

    # Test orbit values at first quarter
    @test raoff(oq1) ≈ 0.0 atol=atol
    @test decoff(oq1) ≈ 1000.0 rtol=rtol
    @test posangle(oq1) ≈ 0.0 atol=atol
    @test projectedseparation(oq1) ≈ 1000.0 rtol=rtol
    
    @test sign(pmra(oq1)) == +1
    @test pmdec(oq1) ≈ 0.0 atol=atol
    @test radvel(oq1) ≈ 0.0 atol=atol

    @test accra(oq1) ≈ 0.0 atol=atol
    @test sign(accdec(oq1)) == -1

    # Test orbit values at second quarter
    @test raoff(oq2) ≈ 1000.0 rtol=rtol
    @test decoff(oq2) ≈ 0.0 atol=atol
    @test posangle(oq2) ≈ π/2 rtol=rtol
    @test projectedseparation(oq2) ≈ 1000.0 rtol=rtol

    @test pmra(oq2) ≈ 0.0 atol=atol
    @test sign(pmdec(oq2)) == -1
    @test radvel(oq2) ≈ 0.0 atol=atol

    @test sign(accra(oq2)) == -1
    @test accdec(oq2) ≈ 0.0 atol=atol

    # Test orbit values at third quarter
    @test raoff(oq3) ≈ 0.0 atol=atol
    @test decoff(oq3) ≈ -1000.0 rtol=rtol
    @test posangle(oq3) ≈ π rtol=rtol
    @test projectedseparation(oq3) ≈ 1000.0 rtol=rtol

    @test sign(pmra(oq3)) == -1
    @test pmdec(oq3) ≈ 0.0 atol=atol
    @test radvel(oq3) ≈ 0.0 atol=atol

    @test accra(oq3) ≈ 0.0 atol=atol 
    @test sign(accdec(oq3)) == +1

    # Test orbit values at fourth quarter
    @test raoff(oq4) ≈ -1000.0 rtol=rtol
    @test decoff(oq4) ≈ 0.0 atol=atol
    @test posangle(oq4) ≈ -π/2 rtol=rtol
    @test projectedseparation(oq4) ≈ 1000.0 rtol=rtol
    
    @test pmra(oq4) ≈ 0.0 atol=atol
    @test sign(pmdec(oq4)) == +1
    @test radvel(oq4) ≈ 0.0 atol=atol

    @test sign(accra(oq4)) == +1
    @test accdec(oq4) ≈ 0.0 atol=atol

    # Compare velocities and accelerations
    @test pmra(oq1) ≈ -pmra(oq3) rtol=rtol
    @test pmdec(oq2) ≈ -pmdec(oq4) rtol=rtol
    @test accdec(oq1) ≈ -accdec(oq3) rtol=rtol
    @test accra(oq2) ≈ -accra(oq4) rtol=rtol
end

## Idealized edge-on Earth with circular orbit at 1 pc 
@testset "Earth, i = 90, e = 0, d = 1 pc" begin
    idealearth = orbit(
        a = 1.0,
        e = 0.0,
        i = π/2,
        ω = 0.0,
        Ω = 0.0,
        tp = 0.0,
        M = 1.0,
        plx = 1000.0
    )

    # Test basic orbit properties
    @test period(idealearth) ≈ PlanetOrbits.year2day_julian rtol=rtol
    @test distance(idealearth) ≈ 1.0 rtol=rtol
    @test meanmotion(idealearth) ≈ 2π rtol=rtol
    @test periastron(idealearth) == 0.0
    @test semiamplitude(idealearth) ≈ 29785.89 rtol=1e-3

    # Orbit solutions at quarters of the orbit
    oq1 = PlanetOrbits.orbitsolve_ν(idealearth, 0.0)
    oq2 = PlanetOrbits.orbitsolve_ν(idealearth, π/2)
    oq3 = PlanetOrbits.orbitsolve_ν(idealearth, π)
    oq4 = PlanetOrbits.orbitsolve_ν(idealearth, 3π/2)

    # Test orbit values at first quarter
    @test raoff(oq1) ≈ 0.0 atol=atol
    @test decoff(oq1) ≈ 1000.0 rtol=rtol
    @test projectedseparation(oq1) ≈ 1000.0 rtol=rtol
    
    @test pmra(oq1) ≈ 0.0 atol=atol
    @test pmdec(oq1) ≈ 0.0 atol=atol
    @test radvel(oq1) ≈ 29785.89 rtol=1e-3

    @test accra(oq1) ≈ 0.0 atol=atol
    @test sign(accdec(oq1)) == -1

    # Test orbit values at second quarter
    @test raoff(oq2) ≈ 0.0 atol=atol
    @test decoff(oq2) ≈ 0.0 atol=atol
    @test projectedseparation(oq2) ≈ 0.0 atol=atol

    @test pmra(oq2) ≈ 0.0 atol=atol
    @test sign(pmdec(oq2)) == -1
    @test radvel(oq2) ≈ 0.0 atol=atol

    @test accra(oq2) ≈ 0.0 atol=atol
    @test accdec(oq2) ≈ 0.0 atol=atol

    # Test orbit values at third quarter
    @test raoff(oq3) ≈ 0.0 atol=atol
    @test decoff(oq3) ≈ -1000.0 rtol=rtol
    @test projectedseparation(oq3) ≈ 1000.0 rtol=rtol

    @test pmra(oq3) ≈ 0.0 atol=atol
    @test pmdec(oq3) ≈ 0.0 atol=atol
    @test radvel(oq3) ≈ -29785.89 rtol=1e-3

    @test accra(oq3) ≈ 0.0 atol=atol 
    @test sign(accdec(oq3)) == +1

    # Test orbit values at fourth quarter
    @test raoff(oq4) ≈ 0.0 atol=atol
    @test decoff(oq4) ≈ 0.0 atol=atol
    @test projectedseparation(oq4) ≈ 0.0 atol=atol
    
    @test pmra(oq4) ≈ 0.0 atol=atol
    @test sign(pmdec(oq4)) == +1
    @test radvel(oq4) ≈ 0.0 atol=atol

    @test sign(accra(oq4)) == +1
    @test accdec(oq4) ≈ 0.0 atol=atol

    # Compare velocities and accelerations
    @test pmdec(oq2) ≈ -pmdec(oq4) rtol=rtol
    @test accdec(oq1) ≈ -accdec(oq3) rtol=rtol
end

## Test varying eccentricity
@testset "Eccentricity" begin
    # Basic eccentric orbit
    eccentric_1AU_1Msun_1pc = orbit(
        a = 1.0, # AU
        e = 0.5,
        i = 0.0,
        ω = 0.0,
        Ω = 0.0,
        tp = 0.0,
        M = 1.0, # M_sun
        plx = 1000.0, # 1000 mas == 1pc
    )
    xs = raoff.(eccentric_1AU_1Msun_1pc, one_year_range)
    ys = decoff.(eccentric_1AU_1Msun_1pc, one_year_range)
    ps = projectedseparation.(eccentric_1AU_1Msun_1pc, one_year_range)

    @test period(eccentric_1AU_1Msun_1pc) ≈ 1.0*PlanetOrbits.year2day_julian rtol=rtol
    @test distance(eccentric_1AU_1Msun_1pc) == 1
    
    # Mean motion should be the same
    @test PlanetOrbits.meanmotion(eccentric_1AU_1Msun_1pc) ≈ 2π rtol=rtol

    # The separation should now be varying
    # By definition of eccentricity 0.5, 1AU and 1PC
    @test maximum(ps) ≈ 1500 rtol=rtol
    @test minimum(ps) ≈ 500 rtol=rtol

    # When argument of periapsis and periastron are both zero, periastron should be in the East, apoastron in the West
    @test maximum(ys) ≈ 500 rtol=rtol
    @test minimum(ys) ≈ -1500 rtol=rtol

    # Rotate Ω
    ecc_rot_Ω = orbit(
        a = 1.0, # AU
        e = 0.5,
        i = 0.0,
        ω = 0.0,
        Ω = deg2rad(90),
        tp = 0.0,
        M = 1.0, # M_sun
        plx = 1000.0, # 1000 mas == 1pc
    )
    xs = raoff.(ecc_rot_Ω, one_year_range)
    ys = decoff.(ecc_rot_Ω, one_year_range)
    # Recall, East is left in the sky.
    # We have rotated  90 degrees CCW.
    @test minimum(xs) ≈ -1500 rtol=rtol
    @test maximum(xs) ≈ 500 rtol=rtol

    # Rotate τ
    ecc_rot_ω = orbit(
        a = 1.0, # AU
        e = 0.5,
        i = 0.0,
        ω = deg2rad(90.0),
        Ω = 0.0,
        tp = 0.0,
        M = 1.0, # M_sun
        plx = 1000.0, # 1000 mas == 1pc
    )
    xs = raoff.(ecc_rot_ω, one_year_range)
    ys = decoff.(ecc_rot_ω, one_year_range)
    # Recall, East is left in the sky.
    # We have rotated  90 degrees CCW.
    @test minimum(xs) ≈ -1500 rtol=rtol
    @test maximum(xs) ≈ 500 rtol=rtol

    # Rotate Ω & τ
    ecc_rot_Ωτ = orbit(
        a = 1.0, # AU
        e = 0.5,
        i = 0.0,
        ω = deg2rad(-90),
        Ω = deg2rad(90),
        tp = 0.0,
        M = 1.0, # M_sun
        plx = 1000.0, # 1000 mas == 1pc
    )
    xs = raoff.(ecc_rot_Ωτ, one_year_range)
    ys = decoff.(ecc_rot_Ωτ, one_year_range)
    # Recall, East is left in the sky.
    # We have rotated  90 degrees CCW.
    @test maximum(ys) ≈ 500 rtol=rtol
    @test minimum(ys) ≈ -1500 rtol=rtol

    # Highly eccentric 
    ecc09 = orbit(
        a = 1.0, # AU
        e = 0.9,
        i = 0.0,
        ω = 0.0,
        Ω = 0.0,
        tp = 0.0,
        M = 1.0, # M_sun
        plx = 1000.0, # 1000 mas == 1pc
    )
    xs = raoff.(ecc09, one_year_range)
    ys = decoff.(ecc09, one_year_range)
    ps = projectedseparation.(ecc09, one_year_range)
    # Loosen the tolerance on these
    @test maximum(ps) ≈ 1900 rtol=1e-4
    @test minimum(ps) ≈ 100 rtol=1e-4

    # Extremely eccentric 
    ecc09 = orbit(
        a = 1.0, # AU
        e = 1-1e-3,
        i = 0.0,
        ω = 0.0,
        Ω = 0.0,
        tp = 0.0,
        M = 1.0, # M_sun
        plx = 1000.0, # 1000 mas == 1pc
    )
    xs = raoff.(ecc09, one_year_range)
    ys = decoff.(ecc09, one_year_range)
    ps = projectedseparation.(ecc09, one_year_range)
    @test maximum(ps) ≈ 1999 rtol=1e-4
    # Loosen the tolerance on these even more (periastron flies by very quickly)
    @test minimum(ps) ≈ 1 rtol=1e1
end 

## Test chain rules
@testset "Chain Rules" begin
    # These tests are broken at MA===0, e>0

    # First test analytic chain rules
    k1(MA) = e->PlanetOrbits.kepler_solver(MA, e)
    k2(e) = MA->PlanetOrbits.kepler_solver(MA, e)
    
    for e in 0:0.1:0.9
        for MA in 0.001:0.1:2π
            @test FiniteDiff.finite_difference_derivative(k2(e), MA) ≈ ForwardDiff.derivative(k2(e), MA) rtol=rtol
        end
    end

    for e = 0.001:0.1:0.9
        for MA in 0.001:0.1:2π
            @test FiniteDiff.finite_difference_derivative(k1(MA), e) ≈ ForwardDiff.derivative(k1(MA), e) rtol=rtol
        end
    end
end

## Test analytic derivatives match numeric derivatives
@testset "PMA & Accel." begin

    # Check analytic derivative properties against ForwardDiff over a big range of orbits
    for t in 0.:35:356.,
        a in 0.1:0.2:3,
        e in 0:0.1:0.9,
        i in deg2rad.([-45, 0, 45, 90, ]),
        ω in deg2rad.([-45, 0, 45, 90, ]),
        Ω in deg2rad.([-45, 0, 45, 90, ])

        elems = orbit(;
            a,
            e,
            i = 0.0,
            ω = 0.0,
            Ω = 0.0,
            tp = 0.0,
            M = 1.0,
            plx = 1000.0, # 1000 mas <-> 1pc
        )

        @test pmra(elems, 100.0) ≈ ForwardDiff.derivative(
            t->raoff(elems, t),
            100.0
        )*PlanetOrbits.year2day_julian

        @test pmdec(elems, 100.0) ≈ ForwardDiff.derivative(
            t->decoff(elems, t),
            100.0
        )*PlanetOrbits.year2day_julian

        @test accra(elems, 100.0) ≈ ForwardDiff.derivative(
            t->pmra(elems, t),
            100.0
        )*PlanetOrbits.year2day_julian

        @test accdec(elems, 100.0) ≈ ForwardDiff.derivative(
            t->pmdec(elems, t),
            100.0
        )*PlanetOrbits.year2day_julian    
    end
end



@testset "Orbit selection" begin
    @test typeof(orbit(;a=1.0, e=0.0, ω=0.0, tp=0.0, M=1.0)) <: RadialVelocityOrbit
    @test typeof(orbit(;a=1.0, e=0.0, ω=0.0, tp=0.0, M=1.0, i=0.1, Ω=0.0)) <: KepOrbit
    @test typeof(orbit(;a=1.0, e=0.0, ω=0.0, tp=0.0, M=1.0, i=0.1, Ω=0.0, plx=100.0).parent) <: KepOrbit
    @test typeof(orbit(;A=100.0, B=100.0, F=100.0, G=-100.0, e=0.5, tp=0.0, M=1.0, plx=100.0)) <: ThieleInnesOrbit
end

@testset "Conventions" begin
    IAU_earth = orbit(
        a = 1.0,
        e = 0.0,
        i = 0.0,
        ω = 0.0,
        Ω = 0.0,
        tp = 0.0,
        M = 1.0,
        plx = 1000.0
    )
    @test period(IAU_earth) ≈ 365.2568983840419 rtol=1e-15 atol=1e-15
    @test meanmotion(IAU_earth) ≈ 2pi*365.2500000000/365.2568983840419 rtol=1e-15 atol=1e-15
end


@testset "Absolute Propagation" begin

    # Test small velocities are approximately linear
    o = orbit(
        a = 1.0, M=1,
        e=0, i=0, ω=0, Ω=0, tp=0, 
        plx = 1000,
        rv =  10,
        ra = 10,
        dec=  0,
        pmra  = 10,
        pmdec =  0,
        ref_epoch = 50000,
    )

    sol0 = orbitsolve(o, 50000)
    @test sol0.compensated.ra2 ≈ o.ra
    @test sol0.compensated.dec2 ≈ o.dec

    sol1 = orbitsolve(o, 50000+365.25)
    # small displacements are approximately linear: should match the result of
    # propagating in the tangent plane
    @test sol1.compensated.ra2 ≈ sol0.compensated.ra2 + o.pmra/60/60/1000
    @test sol1.compensated.dec2 ≈ sol0.compensated.dec2
    @test sol1.compensated.rv2 ≈ sol0.compensated.rv2 atol=1e-2

    @show sol1.compensated.distance2_pc



    # Test small velocities are approximately linear
    o = orbit(
        a = 1.0, M=1,
        e=0, i=0, ω=0, Ω=0, tp=0, 
        plx = 1000,
        rv =  0,
        ra = 10,
        dec=  45,
        pmra  = 10_000,
        pmdec =  0,
        ref_epoch = 50000,
    )

    # These test results were calculated using astropy:
    # from astropy.coordinates import SkyCoord
    # from astropy import units as u
    # from astropy.time import Time
    # from astropy.coordinates import Distance
    # 
    # # Initial coordinate
    # c = SkyCoord(ra=10*u.degree, dec=45*u.degree,
    #              distance=Distance(parallax=1000 * u.mas),
    #              pm_ra_cosdec=10000* u.mas/u.yr,
    #              pm_dec=0* u.mas/u.yr,
    #              radial_velocity=0*u.m/u.s,
    #              obstime=Time(50000, format='mjd'))
    # 
    # # Propagate to a new time
    # new_time = Time(50000 + 365.25, format='mjd')
    # new_coord = c.apply_space_motion(new_time)
    #     Out[21]: 
    # <SkyCoord (ICRS): (ra, dec, distance) in (deg, deg, pc)
    #     (10.0392837, 44.99999327, 1.00000008)
    #  (pm_ra_cosdec, pm_dec, radial_velocity) in (mas / yr, mas / yr, km / s)
    #     (9999.99647434, -4.84813458, 0.02298245)>


    sol1 = orbitsolve(o, 50000+365.25*10)

    @test sol1.compensated.ra2 ≈ 10.0392837
    @test sol1.compensated.dec2 ≈ 44.99999327
    @test sol1.compensated.distance2_pc ≈ 1.00000008 rtol=1e-6
    @test sol1.compensated.pmra2 ≈ 9999.99647434
    @test sol1.compensated.pmdec2 ≈ -4.84813458
    @test sol1.compensated.rv2 ≈ 0.02298245          rtol=1e-6



    o = orbit(
        a = 1.0, M=1,
        e=0, i=0, ω=0, Ω=0, tp=0, 
        plx = 1000,
        rv =  50_000,
        ra = 45,
        dec=  45,
        pmra  = 10_000,
        pmdec =  10_000,
        ref_epoch = 50000,
    )
    
#     c = SkyCoord(ra=45*u.degree, dec=45*u.degree,
#                  distance=Distance(parallax=1000 * u.mas),
#                  pm_ra_cosdec=10000* u.mas/u.yr,
#                  pm_dec=10000* u.mas/u.yr,
#                  radial_velocity=50000*u.m/u.s,
#                  obstime=Time(50000, format='mjd'))
    
#     # Propagate to a new time
#     new_time = Time(50000 + 10*365.25, format='mjd')
#     new_coord = c.apply_space_motion(new_time)
#     <SkyCoord (ICRS): (ra, dec, distance) in (deg, deg, pc)
#     (45.03928266, 45.02775685, 1.00051147)
#  (pm_ra_cosdec, pm_dec, radial_velocity) in (mas / yr, mas / yr, km / s)
#     (9994.61992883, 9984.93147991, 50.04592199)>

    sol1 = orbitsolve(o, 50000+365.25*10)

    @test sol1.compensated.ra2 ≈ 45.03928266
    @test sol1.compensated.dec2 ≈ 45.02775685
    @test sol1.compensated.distance2_pc ≈ 1.00051147 rtol=1e-6
    @test sol1.compensated.pmra2 ≈ 9994.61992883     rtol=1e-6
    @test sol1.compensated.pmdec2 ≈ 9984.93147991    rtol=1e-6
    @test sol1.compensated.rv2 ≈ 50.04592199         rtol=1e-6

end