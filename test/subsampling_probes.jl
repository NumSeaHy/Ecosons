using Revise
using Statistics
# Load modules
includet("../src/EA400Load.jl")
includet("../src/ComputeBathymetry.jl")
# includet("../src/Plot.jl")
# includet("../src/Tides.jl")
# includet("../src/Utils.jl")
# include("../src/Geo.jl")
# includet("../src/Subsampling.jl")
using .EA400Load
using .ComputeBathymetry
# using .Plot
# using .Tides
# # using .Utils
# using DataFrames
# using .Geo
# using .SubSampling

file_pattern = "./data/*raw"
channel = 1

# Load all the files
data, dim = load(channel, file_pattern);

baths = processBathymetries(data, dim, getFirstHit)


# slat, slon, stme, sdepth = radialSubsampling(10., baths[4].latitude, baths[4].longitude, baths[4].time, baths[4].depth)
# # ec_bathymetry_subsampling!(baths, 10)



# # zn = -1
# # lat = baths[1].latitude
# # lon = baths[1].longitude


# # gpsx, gpsy = latlon2utmxy(zn, lat, lon)

# gpsy

# gpsx
function latlon2utmxy(zn, lat::AbstractVector, lon::AbstractVector)
  UTMScaleFactor = 0.9996
  sm_a = 6378137.0
  sm_b = 6356752.314
  sm_EccSquared = 6.69437999013e-03

  ep2 = (sm_a^2 - sm_b^2) / sm_b^2

  # Estimate best UTM-zone
  if length(zn) == 1 && zn <= 0
      zn = round(Int, (mean(filter(!isnan, lon)) + 183) / 6)
  else
      zn = map(zn) do z
          if z <= 0 || isnan(z)
              round(Int, (mean(filter(!isnan, lon)) + 183) / 6)
          else
              z
          end
      end
  end

  lon0 = 6 .* zn .- 183
  cphi = cosd.(lat)
  nu2 = ep2 .* cphi.^2
  N = (sm_a^2 / sm_b) ./ sqrt.(1 .+ nu2)
  t = tand.(lat)
  t2 = t.^2
  l = deg2rad.(lon .- lon0)

  l3coef = 1 .- t2 .+ nu2
  l4coef = 5 .- t2 .+ (9 .+ 4 .* nu2) .* nu2
  l5coef = 5 .+ (t2 .- 18) .* t2 .+ (14 .- 58 .* t2) .* nu2
  l6coef = 61 .+ (t2 .- 58) .* t2 .+ (270 .- 330 .* t2) .* nu2
  l7coef = 61 .+ ((179 .- t2) .* t2 .- 479) .* t2
  l8coef = 1385 .+ ((543 .- t2) .* t2 .- 3111) .* t2

  # Calculate easting (x)
  x = N .* cphi .* l .* (1 .+ (1/6) .* cphi.^2 .* l.^2 .* (l3coef .+ (1/20) .* cphi.^2 .* l.^2 .* (l5coef .+ (1/42) .* cphi.^2 .* l.^2 .* l7coef)))
  x = x .* UTMScaleFactor .+ 500000

  # Calculate northing (y)
  y = ArcLengthOfMeridian.(deg2rad.(lat)) .+ 0.5 .* t .* N .* (cphi.^2 .* l.^2) .* (1 .+ (1/12) .* cphi.^2 .* l.^2 .* (l4coef .+ (1/30) .* cphi.^2 .* l.^2 .* (l6coef .+ (1/56) .* cphi.^2 .* l.^2 .* l8coef)))
  y = y .* UTMScaleFactor
  y .+= 10000000 .* (y .< 0)

  # Define hemisphere
  hm = sign.(lat)

  return x, y, zn, hm
end
function radialSubsampling(sradius::Float64, lat::Vector{Float64}, lon::Vector{Float64}, tme::Vector{Float64}, depth::Vector{Float64})
  nn = length(depth)
  if nn == 1
      return [lat[1]], [lon[1]], [tme[1]], [depth[1]]
  end

  slat, slon, stme, sdepth = Float64[], Float64[], Float64[], Float64[]

  dd = sradius^2
  gpsx, gpsy, zn, hm = latlon2utmxy(-1, lat, lon)
  gpsxa, gpsya = gpsx[1], gpsy[1]

  p_last_valid = 1
  for p in 1:nn
      if isnan(gpsx[p]) || isnan(gpsy[p])
          continue
      end
      rr = (gpsxa - gpsx[p])^2 + (gpsya - gpsy[p])^2
      if rr >= dd || p == 1
          gpsxa, gpsya = gpsx[p], gpsy[p]
          indices = max(1, p-50):min(p+50, nn)
          filtered = filter(i -> (gpsx[i] - gpsx[p])^2 + (gpsy[i] - gpsy[p])^2 < dd, indices)
          if isempty(filtered)
              continue
          end
          sslat, sslon, sstme, ssdep = mean(lat[filtered]), mean(lon[filtered]), mean(tme[filtered]), median(depth[filtered])
          push!(slat, sslat)
          push!(slon, sslon)
          push!(stme, sstme)
          push!(sdepth, ssdep)
          p_last_valid = p
      end
  end

  return slat, slon, stme, sdepth
end

function ArcLengthOfMeridian(ϕ)
  sm_a = 6378137.0
  sm_b = 6356752.314
  n = (sm_a - sm_b) / (sm_a + sm_b)
  α = (sm_a + sm_b) / 2 * (1 + (n^2 / 4) + (n^4 / 64))
  β = (-3 * n / 2) + (9 * n^3 / 16) + (-3 * n^5 / 32)
  γ = (15 * n^2 / 16) - (15 * n^4 / 32)
  δ = (-35 * n^3 / 48) + (105 * n^5 / 256)
  ϵ = (315 * n^4 / 512)

  result = α * (ϕ + β * sin(2 * ϕ) + γ * sin(4 * ϕ) + δ * sin(6 * ϕ) + ϵ * sin(8 * ϕ))
  return result
end


radialSubsampling(10., baths[1].latitude, baths[1].longitude, baths[1].time, baths[1].depth)