"""
Computes the meridional arc length (distance from the equator to latitude `phi`)
based on the WGS84 ellipsoid.

# Arguments
- `phi`: Float64 or Vector{Float64}  
    Latitude(s) in radians.

# Returns
- `result`: Float64 or Vector{Float64}  
    Arc length(s) in meters from the equator to each latitude.
"""
function ArcLengthOfMeridian(
    phi:: Union{Vector{Float64}, Float64}
    ):: Union{Vector{Float64}, Float64}
    # Ellipsoid parameters for WGS84
    sm_a = 6378137.0
    sm_b = 6356752.314

    # Calculate n (flattening parameter)
    n = (sm_a - sm_b) / (sm_a + sm_b)

    # Calculate coefficients for series expansion of meridian arc length
    alpha = 0.5 * (sm_a + sm_b) * (1.0 + 0.25 * n^2 * (1 + 0.0625 * n^2))
    beta = (-1.5 * n) * (1 + (0.375 * n^2) * (1 - n^2 / 6))
    gamma = 0.9375 * n^2 * (1 - 0.5 * n^2)
    delta = -(35 / 48) * n^3 * (1 + 0.5625 * n^2)
    epsilon = (315 / 512) * n^4

    # Compute the meridian arc length from equator to latitude phi (radians)
    result = alpha * (phi +
        beta * sin.(2 .* phi) +
        gamma * sin.(4 .* phi) +
        delta * sin.(6 .* phi) +
        epsilon * sin.(8 .* phi))

    return result
end