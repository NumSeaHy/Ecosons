function ping_class1f(
    cPINGS::Matrix{Float64},
    nClasses::Int = floor(Int, size(cPINGS, 1) / 10),
    fPings::Float64 = 0.95,
    cCLASS::Vector{Int} = collect(1:size(cPINGS, 1)),
    nCLASS::Vector{Int} = Int[],
    fDistance::Function = ping_distance,
    fMerge::Function = logweight,
    cDEPTHS::Vector{Float64} = ones(size(cPINGS, 1)),
    DEPTH0::Float64 = maximum(cDEPTHS)
    )
    npings = size(cPINGS, 1)

    # Initialize class counters if not provided
    if isempty(nCLASS)
        nCLASS = zeros(Int, npings)
        for n in 1:npings
            m = clsintree(cCLASS, n)
            if m > 0
                nCLASS[m] += 1
            end
        end
    end

    # Identify current class heads (each class's representative index)
    cCs = findall(i -> cCLASS[i] == i, 1:npings)

    # Compute initial distances between successive class heads
    dds = fill(Inf, npings)
    for n in 1:length(cCs) - 1
        dds[cCs[n]] = fDistance(
            cPINGS[cCs[n], :], cPINGS[cCs[n + 1], :])
    end

    # Calculate initial fraction of majority classes
    nNCs = sort(nCLASS[cCs]; rev=true)
    fNCs = sum(nNCs[1:nClasses]) / length(cCLASS)

    # Begin merging loop
    while length(cCs) > nClasses && fNCs < fPings
        dvals = dds[cCs]
        dmin, rel_idx = findmin(dvals)

        if !isinf(dmin)
            nn = cCs[rel_idx]
            mm = cCs[rel_idx + 1]

            # Assign mm to class of nn
            cCLASS[mm] = cCLASS[nn]

            # Merge ping and depth info
            merged_ping, merged_depth = fMerge(
                vcat(cPINGS[nn, :]', cPINGS[mm, :]'),
                [cDEPTHS[nn], cDEPTHS[mm]],
                [nCLASS[nn], nCLASS[mm]]
            )
            cPINGS[nn, :] = merged_ping
            cDEPTHS[nn] = merged_depth
            nCLASS[nn] += nCLASS[mm]

            # Recompute distance to next class
            if rel_idx + 2 <= length(cCs)
                dds[nn] = fDistance(
                    cPINGS[nn, :], cPINGS[cCs[rel_idx + 2], :])
            else
                dds[nn] = Inf
            end

        else
            break  # No valid pairs left
        end

        # Update class head list and fraction of kept pings
        cCs = findall(i -> cCLASS[i] == i, 1:npings)
        nNCs = sort(nCLASS[cCs]; rev=true)
        fNCs = sum(nNCs[1:min(nClasses, end)]) / length(cCLASS)
    end
    return cCLASS, nCLASS, cPINGS, cDEPTHS
end
