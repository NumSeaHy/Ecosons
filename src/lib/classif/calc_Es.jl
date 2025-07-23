
function calc_Es(Es::Vector{Tuple{String, Int64, Int64}}, P1::AbstractMatrix, P2::AbstractMatrix)
    n_rows = max(size(P1, 1), size(P2, 1))
    EsValues = fill(NaN, length(Es), n_rows)

    for (n, es) in enumerate(Es)
        echotype = es[1]
        tail_percent = es[2]
        discard_percent = length(es) > 2 ? es[3] : 0

        if echotype == "E1"
            bFr = max(1, floor(Int, size(P1, 2) * (1 - tail_percent / 100)))
            bTo = max(1, floor(Int, size(P1, 2) * (1 - discard_percent / 100)))
            bTo = min(bTo, size(P1, 2))

            lP = @. 10.0 ^ (0.1 * P1[:, bFr:bTo])
            lP[isnan.(lP)] .= 0.0
            E1 = @views 10 .* log10.(sum(lP, dims=2))
            E1[isinf.(E1)] .= NaN
            EsValues[n, 1:size(P1, 1)] .= vec(E1)

        elseif echotype == "E2"
            bFr = max(1, floor(Int, size(P2, 2) * (1 - tail_percent / 100)))
            bTo = max(1, floor(Int, size(P2, 2) * (1 - discard_percent / 100)))
            bTo = min(bTo, size(P2, 2))

            lP = @. 10.0 ^ (0.1 * P2[:, bFr:bTo])
            lP[isnan.(lP)] .= 0.0
            E2 = @views 10 .* log10.(sum(lP, dims=2))
            E2[isinf.(E2)] .= NaN
            EsValues[n, 1:size(P2, 1)] .= vec(E2)

        else
            EsValues[n, :] .= NaN
        end
    end

    return EsValues
end
