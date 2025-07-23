"""Visualization routines for echograms, bathymetry maps, and related data"""
module Plotting

using ..Utils
using ..DataTypes: SonarDataRAW, Bathymetry, TransectCross
using CairoMakie, Dierckx

include("./lib/bathymetry/plot_bathycross.jl")
include("./lib/bathymetry/plot_echobottom.jl")
include("./lib/bathymetry/plot_interpolation.jl")
include("./lib/bathymetry/plot_transects.jl")

export plot_echobottom, plot_bathycross, plot_interpolation, plot_ping, plot_bathymetry_line, 
plot_transects_3D, plot_transects, plot_data_from_file, plot_bathymetry

function plot_ping(bins, data)
    fig = Figure()
    ax = Axis(fig[1, 1], xlabel="Bins", ylabel=L"I\,[\mathrm{dB}]")
    lines!(bins, data, color=:black)
    display(fig)
end

function plot_bathymetry_line(pings, bath_depth)
    fig = Figure()
    ax = Axis(fig[1, 1], xlabel="Pings", ylabel="Depth [m]")
    lines!(pings, bath_depth, color=:black)
    display(fig)
end

"""Plots 2D or 3D scatter data from a delimited text file"""
function plot_data_from_file(
    filename::String,
    x_column::Union{String, Int},
    y_column::Union{String, Int};
    csvsep::Char = ',' ,
    has_headers::Bool = true,
    file_format::String = "csv",
    categorized::Bool = false,
    category_column::Union{String, Int, Nothing} = nothing
    )
    cols, headers = file_format == "csv" ? csvreadcols(filename; hdr = has_headers, csvsep = csvsep) :
                       file_format == "tsv" ? tsvreadcols(filename; hdr = has_headers) :
                       error("Unsupported file format")
    println("Headers: ", headers)
    fig = Figure()
    if categorized
        xyz = extractCols(headers, cols, x_column, y_column, category_column)
        ax = Axis3(fig[1, 1])
        scatter!(ax, xyz[1], xyz[2], xyz[3])
    else
        xy = extractCols(headers, cols, x_column, y_column)
        ax = Axis(fig[1, 1])
        scatter!(ax, xy[1], xy[2])
    end
    display(fig)
end

function plot_bathymetry(x, y)    
    fig = Figure()
    ax = Axis(fig[1, 1], xlabel = "Longitude", ylabel = "Latitude")
    scatter!(ax, x, y)
    display(fig)
end


end