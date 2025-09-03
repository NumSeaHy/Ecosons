using Ecosons
using CairoMakie
using Test

@testset begin
    lat = [45.0, 45.1]
    lon = [8.0, 8.1]
    zn = -1  # Let it compute zone

    x, y, zn_out, hm = latlon2utmxy(zn, lat, lon)
    println("x = $x, y = $y, zone = $zn_out, hemisphere = $hm")

    x, y, zone, hemisphere = latlon2utm(45.0, 8.0)
    println("Easting: $x, Northing: $y, Zone: $zone, Hemisphere: $hemisphere")

    t = hms2t([14, 30, 0])  # 14:30:00
    println("Fractional hours: $t")

    # Sample data
    G = [
        GPSDataRAW(10.0, 45.0, 8.0),
        GPSDataRAW(20.0, 45.001, 8.002),
        GPSDataRAW(30.0, 45.005, 8.005)
    ]

    d2o = gcoords2distances(G)
    println("Distances to first GPS fix: ", d2o)

    file_name = joinpath(@__DIR__, "..", "data", "sample_data.txt")
    lat, lon, P = trload(file_name, 2, 3, 5)

    println("Latitude: ", lat)
    println("Longitude: ", lon)
    println("Intensity (P): ", P)
end
