function transect_depths(P, Q, nField::Float64, thr::Int64)
    npings = size(P, 1)
    depths = zeros(Float64, npings)
    Rs = zeros(Int, npings)

    cs = [q.soundVelocity for q in Q]
    ts = [q.sampleInterval for q in Q]

    R0 = round.(Int, nField ./ (0.5 .* cs .* ts) .+ 2)

    for p in 1:npings
        ping = P[p, :]
        rstart = R0[p]
        if rstart > length(ping)
            continue
        end

        window = ping[rstart:end]
        Pmx, rrel = findmax(window)
        R = rrel + rstart - 1

        while R > rstart && ping[R - 1] > Pmx - thr
            R -= 1
        end

        Rs[p] = R
        depths[p] = 0.5 * cs[p] * ts[p] * (R - 2)
    end

    return depths, Rs
end
