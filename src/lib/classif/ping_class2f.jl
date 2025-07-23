function ping_class2f(
    cPINGS::Matrix{Float64}, 
    nClasses::Int = floor(Int, size(cPINGS, 1) ÷ 10),
    fPings::Float64 = 0.95,
    cCLASS::Vector{Int} = collect(1:size(cPINGS, 1)),
    nCLASS::Union{Vector{Int}, Nothing} = nothing,
    fDistance::Function = ping_distance,
    fMerge::Function = logweight,
    cDEPTHS::Vector{Float64} = ones(size(cPINGS, 1)),
    DEPTH0::Union{Float64, Nothing} = nothing
    )

    N = size(cPINGS, 1)
    DEPTH0 = DEPTH0 === nothing ? maximum(cDEPTHS) : DEPTH0

    # Initialize class population count
    if nCLASS === nothing || isempty(nCLASS)
        nCLASS = zeros(Int, N)
        for n in 1:N
            m = clsintree(cCLASS, n)
            if m > 0
                nCLASS[m] += 1
            end
        end
    end

    # Initial class representatives (pure classes)
    cCs = findall(i -> cCLASS[i] == i, 1:N)
    dds = fill(Inf, length(cCs), length(cCs))

    for n in eachindex(cCs)
        for m in n+1:length(cCs)
            dds[n, m] = fDistance(
                cPINGS[cCs[n], :], cPINGS[cCs[m], :])      
        end
    end


    nCs = length(cCs)
    fNCs = sum(sort(nCLASS[cCs], rev = true)[1:min(nClasses, end)]) / length(cCLASS)
    while nCs > nClasses && fNCs < fPings
        dmin = Inf
        nn, mm = 0, 0
        nmin, mmin = 0, 0
        for n in eachindex(cCs)
            if n == length(cCs)
                 continue  # or skip last safely
            end
            d, mrel = findmin(dds[n, n + 1 : end])
            m = mrel + n
            if d < dmin
                dmin = d
                nn, mm = cCs[n], cCs[m]
                nmin, mmin = n, m
            end
        end

        if isfinite(dmin) && mmin != 0
            # Merge mm into nn
            cCLASS[mm] = cCLASS[nn]
            merged_ping, merged_depth = fMerge(
                reduce(vcat, [cPINGS[nn, :]', cPINGS[mm, :]']),
                [cDEPTHS[nn], cDEPTHS[mm]],
                [nCLASS[nn], nCLASS[mm]]
            )
            cPINGS[nn, :] = merged_ping
            cDEPTHS[nn] = merged_depth
            nCLASS[nn] += nCLASS[mm]
            nCs -= 1

            # Update dds and cCs
            idxs = vcat(1:mmin - 1, mmin + 1:length(cCs))  
            dds = dds[idxs, idxs]                      
            cCs = cCs[idxs]                            
            for m in nmin+1:length(cCs)
                dds[nmin, m] = fDistance(cPINGS[nn, :], cPINGS[cCs[m], :])
            end
        else
            break
        end

        nNCs = sort(nCLASS[cCs], rev = true)
        fNCs = sum(nNCs[1:nClasses]) / length(cCLASS)
    end


    return cCLASS, nCLASS, cPINGS, cDEPTHS
end
