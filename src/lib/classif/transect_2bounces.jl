function transect_2bounces(P::AbstractMatrix{<:Real}, R1::AbstractVector{<:Real}, thr::Real)
    npings = size(P, 1)
    R2 = fill(NaN, npings)
    RR = floor.(Int, 1.75 .* R1)

    for n in 1:npings
        rr = RR[n]
        if isnan(rr) || rr < 1 || rr > size(P, 2)
            continue
        end
        ping = P[n, :]
        if rr > length(ping)
            continue
        end
        segment = ping[rr:end]
        if isempty(segment)
            continue
        end
        mx, p = findmax(segment)
        p += rr - 1
        while p > rr && ping[p - 1] > mx - thr
            p -= 1
        end
        R2[n] = p
    end

    return R2
end
