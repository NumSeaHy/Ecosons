using ..ComputeBathymetry: bathymetryCrosses

"""
Compute bathymetric transect crossings and optionally convert intersection coordinates to UTM.

This function wraps `bathymetryCrosses` to identify intersection points between pairs of 
transects and augments the result with UTM coordinates if requested.

# Arguments
- `baths`: Array of bathymetric transect data structures. Each element should include 
  `.latitude`, `.longitude`, `.depth`, and `.time` fields.
- `point_subsampling`: Integer step size used for defining line segments along each transect.
- `use_utm`: Boolean flag. If `true`, converts intersection points from lat/lon to UTM coordinates.

# Returns
- `TRANSECTCROSS`: A `TransectCross` struct populated with intersection data and 
  optionally with UTM fields (`utmX1`, `utmY1`, `utmX2`, `utmY2`).
- `use_utm`: Echo of the input flag, useful for downstream plotting or labeling.

# Notes
- UTM zone is calculated based on the first crossing longitude.
- Coordinate conversion is skipped if no crossings are detected (`isempty(TRANSECTCROSS.lon1)`).
"""
function computeCrosses(
  baths:: Array{Bathymetry};
  point_subsampling:: Int = 5,
  use_utm::Bool = false
  ):: Tuple{TransectCross, Bool}

  if isempty(baths)
    error("Input `baths` is empty. At least two transects are required.")
  elseif length(baths) < 2
    error("At least two transects are needed to compute intersections.")
  end

  if point_subsampling < 1
    error("Invalid `point_subsampling`: must be ≥ 1")
  end

  # Generate cross-section data
  @time TRANSECTCROSS = bathymetryCrosses(baths, point_subsampling)
  # Perform lat/lon → UTM conversion if requested
  if use_utm && !isempty(TRANSECTCROSS.lon1)
    # Compute UTM zone based on first longitude
    TRANSECTCROSS.utmZN = round(Int, (TRANSECTCROSS.lon1[1] + 183) / 6)

    # Convert first and second lat/lon coordinates to UTM
    TRANSECTCROSS.utmX1, TRANSECTCROSS.utmY1 = latlon2utmxy(TRANSECTCROSS.utmZN, TRANSECTCROSS.lat1, TRANSECTCROSS.lon1)

    TRANSECTCROSS.utmX2, TRANSECTCROSS.utmY2 = latlon2utmxy(TRANSECTCROSS.utmZN, TRANSECTCROSS.lat2, TRANSECTCROSS.lon2)
  end

  return TRANSECTCROSS, use_utm
end

