module SubSampling

# Load packages
using Revise
includet("Utils.jl")
includet("ComputeBathymetry.jl")

export ec_bathymetry_subsampling!

"""
    ec_bathymetry_subsampling!(bathymetries::Vector{Bathymetry}) -> (Int, String)

Perform bathymetry subsampling based on a user-input search radius, directly modifying each bathymetry entry.

# Arguments
- `bathymetries`: A vector of `Bathymetry` objects to be subsampled.

# Returns
- An error code (`0` for success, `1` for invalid input) and an error description.

# Example
```julia
bathymetries = [Bathymetry("Transect1", lat1, lon1, time1, depth1), Bathymetry("Transect2", lat2, lon2, time2, depth2)]
err, err_desc = ec_bathymetry_subsampling!(bathymetries)
"""
function ec_bathymetry_subsampling!(bathymetries, sradius)
  if sradius <= 0
    return 1, "Invalid search radius; aborting."
  end

  for i in eachindex(bathymetries)
      if !isempty(bathymetry.depth)
          slat, slon, stme, sdep = radialSubsampling(sradius, bathymetries[i].latitude, bathymetries[i].longitude, bathymetries[i].time, bathymetries[i].depth)
          bathymetries[i].latitude = slat
          bathymetries[i].longitude = slon
          bathymetries[i].time = stme
          bathymetries[i].depth = sdep
      end
  end

end





end