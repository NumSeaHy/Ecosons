# Assuming the Bathymetry type is defined as before
struct Bathymetry
  latitude::Vector{Float64}
  longitude::Vector{Float64}
  depth::Vector{Float64}
end

# And you have a vector of Bathymetry instances:
bathymetries = [Bathymetry([1.0, 2.0], [3.0, 4.0], [5.0, 6.0]),
              Bathymetry([7.0, 8.0], [9.0, 10.0], [11.0, 12.0])]

# Collecting all latitudes, longitudes, and depths in separate arrays
latitudes = [bathy.latitude for bathy in bathymetries]
longitudes = [bathy.longitude for bathy in bathymetries]
depths = [bathy.depth for bathy in bathymetries]

# Concatenating all collected arrays using vcat
latitudes_combined = vcat(latitudes...)
longitudes_combined = vcat(longitudes...)
depths_combined = vcat(depths...)

# Now latitudes_combined, longitudes_combined, and depths_combined contain all data concatenated.
