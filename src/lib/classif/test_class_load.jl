include("transect_depths.jl")
include("transect_2bounces.jl")
include("representative.jl")
include("pingCorrect.jl")
include("pingCorrect2.jl")
include("../formats/simradRAW.jl")
include("pingStretch.jl")

using Printf, JLD2
using ..ComputeBathymetry: compute_bottom 
using ..Models: convert_true_depth
using ..LoadData: saveJLD2, loadJLD2

function test_class_load(lsRAW, ping_distance, ping_average; jld2_path::Union{Nothing, String} = nothing,
    load_cached::Bool = true, nchan = 1, depthInf = 40.0, npings = 10, dnpings = 10, depthRef = 1.0)

    transectNo = Int[]
    pingFromNo = Int[]
    pingToNo   = Int[]
    PS0 = Vector{Vector{Float64}}()
    PS  = Vector{Vector{Float64}}()
    PS20 = Vector{Vector{Float64}}()
    PS2  = Vector{Vector{Float64}}()
    Rbins = Float64[]
    depthS = Float64[]
    latS = Float64[]
    lonS = Float64[]

    nsegment = 0

    Linf = 0

    sonar_array = nothing; valid_names = nothing #Go to test/SaveExportJLD2.jl to create them if they are not yet

    if load_cached && jld2_path !== nothing
        try
            sonar_array = loadJLD2(jld2_path; isdata=true)
            valid_names = [x[1] for x in sonar_array]
            println("Loaded sonar data from $(jld2_path).jld2")
        catch e
            println("Failed to load cached data: ", e.msg)
            println("Proceeding to parse raw files...")
        end
    end
    for (nraw, raw_name) in enumerate(lsRAW)
        try
            if isnothing(sonar_array)
                P, Q, G = simradRAW(raw_name)
            else
                if raw_name in valid_names
                    idx = findfirst(==(raw_name), valid_names)
                    P, Q, G = sonar_array[idx][2:end]  # Skip the name (first element)
                else
                    continue
                end
            end
            println("Loaded: $(raw_name)")

            # Skip empty RAWs
            if length(P) != 2 || size(P[1], 2) == 0 || size(P[2], 2) == 0
                println("Unable to load RAW $raw_name")
                continue
            end

            nField = 2.5  # meters

            P[nchan] = P[nchan][:, .!map(col -> all(isnan.(col)), eachcol(P[nchan]))]
            bottomDepths, R = transect_depths(P[nchan], Q[nchan], nField, 40) #40 dB de umbral
            push!(bottomDepths, bottomDepths[end])
            bottomDepths = bottomDepths[1:size(P[nchan], 1)]
            blgt = 0.5 * Q[nchan][1].soundVelocity * Q[nchan][1].sampleInterval
            alphas = [q.absorptionCoefficient for q in Q[nchan]]
            R2 = transect_2bounces(P[nchan], R, 30)
            R = Float64.(R)
            R2 = Float64.(R2)
            R[bottomDepths .<= nField] .= NaN
            R2[bottomDepths .<= nField] .= NaN
            tms = [g.time for g in G[nchan]]
            lat = [g.latitude for g in G[nchan]]
            lon = [g.longitude for g in G[nchan]]
            R[tms .< 0] .= NaN
            R2[tms .< 0] .= NaN
            for p in npings:npings:(length(R) - npings)
                pFrom = max(1, p - dnpings)
                pTo   = min(p + dnpings, length(R))
                pmsk = collect(pFrom:pTo)
                pmsk = filter(i -> !isnan(R[i]) && !isnan(P[nchan][i, 1]) && bottomDepths[i] > depthRef, pmsk)

                if length(pmsk) < dnpings
                    continue
                end

                RP = R[pmsk]
                latP = lat[pmsk]
                lonP = lon[pmsk]
                dpthP = bottomDepths[pmsk]
                if nraw == 1
                    Linf = round(Int, depthInf / blgt)
                end
                PP = fill(NaN, length(pmsk), Linf)
                PP2 = fill(NaN, length(pmsk), Linf)

                for (npp, pp) in enumerate(pmsk)
                    PP[npp, :], PP2[npp, :] = pingStretch(P[nchan][pp, :], R[pp], Linf, R2[pp])
                end
                PPr, dpthPr = representative(PP, copy(dpthP), ping_distance, ping_average, 0.5)
                PP2r, _ = representative(PP2, 2 .* copy(dpthP), ping_distance, ping_average, 0.5)
                alpha_ch = Float64.(mean(alphas[1]))
                PPP = pingCorrect(PPr, dpthPr, depthRef, depthInf, alpha_ch / 1000, 40)
                PPP2 = pingCorrect2(PP2r, dpthPr, depthRef, depthInf, alpha_ch / 1000, 30)
                nsegment += 1
                push!(transectNo, nraw)
                push!(pingFromNo, pFrom)
                push!(pingToNo, pTo)
                # Ensure row vectors
                PPr = reshape(PPr, 1, :)
                PPP = reshape(PPP, 1, :)
                PP2r = reshape(PP2r, 1, :)
                PPP2 = reshape(PPP2, 1, :)

                push!(PS0, vec(PPr))
                push!(PS,  vec(PPP))
                push!(PS20, vec(PP2r))
                push!(PS2,  vec(PPP2))

                push!(depthS, dpthPr)
                push!(Rbins, isnan(dpthPr / blgt) ? NaN : floor(Int, dpthPr / blgt))
                push!(latS, mean(latP))
                push!(lonS, mean(lonP))

                @printf(stderr, "\r%06d", nsegment)
            end
        catch e
            if isa(e, EOFError)
                println("EOFError encountered for file: ", raw_name, ". Skipping this file.")
            else
                # Re-throw the exception if it's not an EOFError
                rethrow()
            end
        end
    end

    PS0 = reduce(vcat, (x' for x in PS0))
    PS  = reduce(vcat, (x' for x in PS))
    PS20 = reduce(vcat, (x' for x in PS20))
    PS2  = reduce(vcat, (x' for x in PS2))

    return transectNo, pingFromNo, pingToNo, PS0, PS, PS20, PS2, Rbins, depthS, latS, lonS
end

