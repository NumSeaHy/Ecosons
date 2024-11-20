module Resampling

using Revise

includet("ComputeBathymetry.jl")
includet("Slopes.jl")
using ..ComputeBathymetry
export resampleBathymetry

"""
    resampleBathymetry(bathymetries::Vector{Bathymetry}, slopes::Vector{Slopes}, srad::Float64, nrsp::Int) -> Vector{Bathymetry}

Resamples a collection of bathymetry data using precomputed slopes to simulate new sampling points.

# Arguments
- `bathymetries`: Vector of Bathymetry objects to resample.
- `slopes`: Vector of Slopes objects corresponding to each Bathymetry object.
- `srad`: Sampling radius in meters for the simulation.
- `nrsp`: Number of simulated samples per original bathymetry point.

# Returns
- `Vector{Bathymetry}`: New bathymetry objects with simulated sampling based on the original data and slopes.
"""
function resampleBathymetry(bathymetries, slopes, srad::Float64, nrsp::Int)
  Rt = 6367444.66  # Earth radius (approx.)
  dam = (180 / π) * 1 / 6356752.314  # Conversion factor for lat-lon

  newBathymetries = Vector{Bathymetry}()

  for (nt, bathy) in enumerate(bathymetries)
      lt = length(bathy.time)

      # Preallocate new arrays
      totalSamples = lt * nrsp
      newLatitudes = Vector{Float64}(undef, totalSamples)
      newLongitudes = Vector{Float64}(undef, totalSamples)
      newDepths = Vector{Float64}(undef, totalSamples)
      newTimes = Vector{Float64}(undef, totalSamples)

      index = 1
      for n in 1:lt
          clat = cos(π * bathy.latitude[n] / 180)
          rr = srad * sqrt(1 - slopes[nt].cang[n]^2)
          for _ in 1:nrsp
              dx, dy, dz = rr * randn(), rr * randn(), slopes[nt].slope[n] * rr * randn()

              newLatitudes[index] = bathy.latitude[n] + dy * dam
              newLongitudes[index] = bathy.longitude[n] + dx * dam / clat
              newDepths[index] = bathy.depth[n] + dz
              newTimes[index] = bathy.time[n]  # This assumes time replication; adjust if necessary

              index += 1
          end
      end

      push!(newBathymetries, Bathymetry(bathy.name, newTimes, newLatitudes, newLongitudes, newDepths))
  end

  return newBathymetries
end





end