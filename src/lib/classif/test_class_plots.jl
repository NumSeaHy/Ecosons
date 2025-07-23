using CairoMakie
using Statistics
using StatsBase
using NumUtils

include("clsplot.jl")

# Figure 1
f1 = Figure()
ax1 = Axis(f1[1,1])
clsplot(tCLASS, cCs, lonS, latS; ax=ax1)
axislimits!(ax1, minimum(lonS), maximum(lonS), minimum(latS), maximum(latS))
axisaspect(ax1, DataAspect())
ax1.title = test_title
f1

# Figure 2
f2 = Figure()
ax2 = Axis(f2[1,1])
for (n, cls) in enumerate(cCs)
    cp = cPINGS[cls, :]
    avg = nnmean(PS[tCLASS .== cls, :], dims=1)
    std = nnstd(PS[tCLASS .== cls, :], dims=1)
    x = 1:length(cp)
    color = get(Makie.wong_colors(), mod(n,6)+1, :black)

    lines!(ax2, x, cp, label="Class $cls", color=color)
    scatter!(ax2, x, vec(avg) .+ vec(std), color=color, marker=:circle)
    scatter!(ax2, x, vec(avg) .- vec(std), color=color, marker=:circle)
end
axislegend(ax2)
ax2.title = test_title
f2

# Figure 3
f3 = Figure()
ax3 = Axis(f3[1,1])
for n in 1:min(5, length(cCs))
    cls = cCs[n]
    cp = cPINGS[cls, :]
    med = mapslices(median, PS[tCLASS .== cls, :], dims=1)
    rng = 0.5 * mapslices(x -> maximum(x) - minimum(x), PS[tCLASS .== cls, :], dims=1)
    x = 1:length(cp)
    color = get(Makie.wong_colors(), mod(n,6)+1, :black)

    lines!(ax3, x, cp, label="Class $cls", color=color)
    scatter!(ax3, x, vec(med) .+ vec(rng), color=color, marker=:circle)
    scatter!(ax3, x, vec(med) .- vec(rng), color=color, marker=:circle)
end
axislegend(ax3)
ax3.title = test_title
f3

# Figure 4
f4 = Figure()
ax4 = Axis(f4[1,1])
for n in 1:min(5, length(cCs))
    cls = cCs[n]
    cp = cPINGS[cls, :]
    mx = mapslices(maximum, PS[tCLASS .== cls, :], dims=1)
    mn = mapslices(minimum, PS[tCLASS .== cls, :], dims=1)
    x = 1:length(cp)
    color = get(Makie.wong_colors(), mod(n,6)+1, :black)

    lines!(ax4, x, cp, label="Class $cls", color=color)
    scatter!(ax4, x, vec(mx), color=color, marker=:circle)
    scatter!(ax4, x, vec(mn), color=color, marker=:circle)
end
axislegend(ax4)
ax4.title = test_title
f4

# Figure 5
f5 = Figure()
ax5 = Axis(f5[1,1])
clsplot(rCLASS, cCs, lonS, latS; ax=ax5)
axislimits!(ax5, minimum(lonS), maximum(lonS), minimum(latS), maximum(latS))
axisaspect(ax5, DataAspect())
ax5.title = test_title
f5

# Figure 6
f6 = Figure()
ax6 = Axis(f6[1,1])
for n in 1:min(5, length(cCs))
    cls = cCs[n]
    cp = cPINGS[cls, :]
    mx = mapslices(maximum, PS[rCLASS .== cls, :], dims=1)
    mn = mapslices(minimum, PS[rCLASS .== cls, :], dims=1)
    x = 1:length(cp)
    color = get(Makie.wong_colors(), mod(n,6)+1, :black)

    lines!(ax6, x, cp, label="Class $cls", color=color)
    scatter!(ax6, x, vec(mx), color=color, marker=:circle)
    scatter!(ax6, x, vec(mn), color=color, marker=:circle)
end
axislegend(ax6)
ax6.title = test_title
f6

function clsplot(class_labels, class_ids, lon, lat; ax=nothing)
    ax = ax === nothing ? Axis() : ax
    for cid in class_ids
        mask = class_labels .== cid
        scatter!(ax, lon[mask], lat[mask], label="Class $cid")
    end
    axislegend(ax)
    return ax
end

