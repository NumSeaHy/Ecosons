using BenchmarkTools
using Test
using JSON
using EcoSons
using CairoMakie

@testset begin
    json_path = joinpath(@__DIR__, "../config/params.json")
    config = JSON.parsefile(json_path)
    dir = joinpath(@__DIR__, config["data_dir"])
    files = filter(f -> endswith(f, ".raw"), readdir(dir))
    full_paths = joinpath.(dir, files)
    channel = config["channel"]
    transect = config["transect"]
    println("Loaded: ", extract_identifier(full_paths[transect])) 
    # === Load data ===
    P, Q, G, W = simradRAW(full_paths[transect])
    P, Q, G, W = P[channel], Q[channel], G[channel], W[channel]
    # Early exit if W is empty
    if isempty(W)
        @warn "Waveform data W is empty — skipping broadband frequency test."
        return  # Skip rest of testset
    end
    #W: (num_pings, num_samples, num_beams)

    fW, f_sel, P, Pmf = computeBBFrequency(Q, W) #see /docs/computeBBFrequency

    # Helper for range axis:
    range_axis = 0.5 .* (1:size(Pmf, 2)) .* Q[1].soundVelocity .* Q[1].sampleInterval

    # 1. Power Spectrum at selected range bin
    range_idx = div(size(P[1], 2), 2)
    power_vs_freq = [mean(P[nf][:, range_idx]) for nf in 1:length(f_sel)]

    fig1 = Figure(size = (700, 400))
    ax1 = Axis(fig1[1, 1], xlabel="Frequency (Hz)", ylabel="Power (dB)", title="Power Spectrum at Range Bin $range_idx")
    lines!(ax1, f_sel, power_vs_freq)
    display(fig1)

    # 2. Power vs Range at fixed frequency
    freq_idx = div(length(f_sel), 2)
    power_vs_range = mean(P[freq_idx], dims=1) |> vec

    fig2 = Figure(size = (700, 400))
    ax2 = Axis(fig2[1, 1], xlabel="Range (m)", ylabel="Power (dB)", title="Power vs Range 
    at Frequency $(round(f_sel[freq_idx]/1000, digits=2)) kHz")
    lines!(ax2, range_axis, power_vs_range)
    display(fig2)

    # 3. Heatmap: Power vs Frequency and Range (for first ping)
    ping_idx = 1
    power_matrix = hcat([P[nf][ping_idx, :] for nf in 1:length(f_sel)]...)
    fig3 = Figure(size = (700, 500))
    ax3 = Axis(fig3[1, 1], xlabel="Range (m)", ylabel="Frequency (kHz)", title="Power Heatmap (Ping $ping_idx)")
    hm = heatmap!(ax3, range_axis, f_sel ./ 1000, power_matrix, colormap=:viridis)
    Colorbar(fig3[1, 2], hm, label="Power (dB)")
    display(fig3)

    # 4. Matched Filter Power Profile
    fig4 = Figure(size = (700, 400))
    ax4 = Axis(fig4[1, 1], xlabel="Range (m)", ylabel="Power (dB)", title="Matched Filter Power Profile")
    lines!(ax4, range_axis, mean(Pmf, dims=1) |> vec)
    display(fig4)
end