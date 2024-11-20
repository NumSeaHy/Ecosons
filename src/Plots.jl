module Plots

using CairoMakie
using LaTeXStrings
using Formatting

export ec_plot_echobottom, plot_ping, plot_bathymetry_line, plot_transects

function ec_plot_echobottom(SONAR_DATA)

    # Check data availability
    if isempty(SONAR_DATA)
        return 1, "No echogram available"
    end
  
    # Assuming gminput is a placeholder for getting graphical input, replaced with a simple println for demonstration
    println("Select ping range (default entire transect): ")
    # For demonstration, using predefined range. Implement actual input mechanism as needed.
    rg = 1:size(SONAR_DATA, 1)

    println("Select bin range (default whole range): ")
    
    # For demonstration, using predefined range. Implement actual input mechanism as needed.
    bn = 1:size(SONAR_DATA, 2)

    # Display echogram
    fig = Figure()
    ax = Axis(fig[1, 1], xlabel="Pings", ylabel="Bins", yreversed=true)
    hm = heatmap!(SONAR_DATA[rg, bn], colormap = :viridis)
    Colorbar(fig[1, 2], hm, label=L"I\,[\mathrm{dB}]")
    
    display(fig)
end

function plot_ping(bins, data)
    fig = Figure()
    ax = Axis(fig[1, 1], xlabel="Bins", ylabel=L"I\,[\mathrm{dB}]")
    lines!(bins, data, color=:black)
    display(fig)
end

function plot_bathymetry_line(pings, bathymetry)
    fig = Figure()
    ax = Axis(fig[1, 1], xlabel="Pings", ylabel="Depth [m]")
    lines!(pings, bathymetry, color=:black)
    display(fig)
end



function plot_transects(latitudes, longitudes)
    
    fig = Figure() # Create a new figure
    ax = Axis(fig[1, 1], xlabel="Longitude", ylabel="Latitude",
    ytickformat = v -> format.(v, commas=false, precision=5),
    xtickformat = v -> format.(v, commas=false, precision=5)) # Create an axis with labels and title
    #hideydecorations!(ax, ticks=true, grid=false)

    lon_min, lon_max = extrema(reduce(vcat, longitudes))
    lat_min, lat_max = extrema(reduce(vcat, latitudes))
    padding = 0.05 # Padding percentage
    lon_pad = (lon_max - lon_min) * padding
    lat_pad = (lat_max - lat_min) * padding
    xlims!(ax, lon_min - lon_pad, lon_max + lon_pad)
    ylims!(ax, lat_min - lat_pad, lat_max + lat_pad + 0.000005)

    # Loop through the transects and plot them
    for i in eachindex(latitudes)
        lat = latitudes[i]
        lon = longitudes[i]
        lines!(ax, lon, lat) # Plot each transect
    end

    fig
end

 
end