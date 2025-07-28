using CairoMakie
using Statistics
using StatsBase
using NumUtils

include("clsplot.jl")


"""
Generate a map-style classification plot using `clsplot`.
"""
function plot_class_map(tCLASS, cCs, lonS, latS)
    # Figure 1
    f1 = Figure()
    ax1 = Axis(f1[1,1])
    clsplot(tCLASS, cCs, lonS, latS; ax=ax1)
    axislimits!(ax1, minimum(lonS), maximum(lonS), minimum(latS), maximum(latS))
    axisaspect(ax1, DataAspect())
    display(f1)
end

"""
Plots the mean ± standard deviation of each class compared to a canonical curve.
"""
function plot_mean_std(tCLASS, cCs, PS, cPINGS)
    f2 = Figure()
    ax2 = Axis(f2[1,1])
    for (n, cls) in enumerate(cCs)
        cp = cPINGS[cls, :]
        avg = nnmean(PS[tCLASS .== cls, :], dims = 1)
        std = nnstd(PS[tCLASS .== cls, :], dims = 1)
        x = 1:length(cp)
        color = get(Makie.wong_colors(), mod(n, 6) + 1, :black)
        lines!(ax2, x, cp, label="Class $cls", color=color)
        scatter!(ax2, x, vec(avg) .+ vec(std), color=color, marker=:circle)
        scatter!(ax2, x, vec(avg) .- vec(std), color=color, marker=:circle)
    end
    axislegend(ax2)
    display(f2)
end

"""
Plots the median ± half range (max-min)/2 of each class compared to canonical curves.
"""
function plot_median_range(tCLASS, cCs, PS, cPINGS)
    f3 = Figure()
    ax3 = Axis(f3[1,1])
    for n in 1:min(5, length(cCs))
        cls = cCs[n]
        cp = cPINGS[cls, :]
        med = mapslices(median, PS[tCLASS .== cls, :], dims=1)
        rng = 0.5 * mapslices(x -> maximum(x) - minimum(x), PS[tCLASS .== cls, :], dims=1)
        x = 1:length(cp)
        color = get(Makie.wong_colors(), mod(n,6) + 1, :black)
        lines!(ax3, x, cp, label="Class $cls", color=color)
        scatter!(ax3, x, vec(med) .+ vec(rng), color=color, marker=:circle)
        scatter!(ax3, x, vec(med) .- vec(rng), color=color, marker=:circle)
    end
    axislegend(ax3)
    display(f3)
end

"""
Plots the min and max values of each class's samples compared to canonical curves.
"""
function plot_min_max(tCLASS, cCs, PS, cPINGS)
    f4 = Figure()
    ax4 = Axis(f4[1,1])
    for n in 1:min(5, length(cCs))
        cls = cCs[n]
        cp = cPINGS[cls, :]
        mx = mapslices(maximum, PS[tCLASS .== cls, :], dims=1)
        mn = mapslices(minimum, PS[tCLASS .== cls, :], dims=1)
        x = 1:length(cp)
        color = get(Makie.wong_colors(), mod(n,6) + 1, :black)
        lines!(ax4, x, cp, label="Class $cls", color=color)
        scatter!(ax4, x, vec(mx), color=color, marker=:circle)
        scatter!(ax4, x, vec(mn), color=color, marker=:circle)
    end
    axislegend(ax4)
    display(f4)
end

