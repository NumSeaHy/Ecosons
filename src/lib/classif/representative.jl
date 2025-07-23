function representative(P::AbstractMatrix, depth::AbstractVector, 
                        distance::Function, average::Function, fraction::Real)
    npings = size(P, 1)
    Pr = Float64[]
    depthr = NaN

    # Initialize classes and counts
    Pclass = collect(1:npings)
    Pcount = ones(Int, npings)

    tPcount = copy(npings)
    countX = floor(Int, npings * fraction)

    while tPcount > 1
        dmin = Inf
        nmin = -1
        mmin = -1

        # Iterate over unique pairs (n,m) with n > m
        reps = findall(i -> Pclass[i] == i, 1:npings)
        for n in reps
            for m in reps
                if m >= n
                    continue
                end
                d = distance(P[n, :], P[m, :])
                if d < dmin
                    dmin = d
                    nmin = n
                    mmin = m   
                end
            end
        end

        if !isinf(dmin)
            # Merge classes: assign class of mmin to nmin
            Pclass[nmin] = Pclass[mmin]
            # Average the two pings
            P[mmin, :], depth[mmin] = average(
                vcat(P[mmin, :]', P[nmin, :]'),
                [depth[mmin], depth[nmin]],
                [Pcount[mmin], Pcount[nmin]]
            )

            depth[nmin] = depth[mmin]
            Pcount[mmin] += Pcount[nmin]
            tPcount -= 1

            if Pcount[mmin] > countX
                Pr = copy(P[mmin, :])
                depthr = depth[mmin]
                break
            end
        else
            println("NaN distance")
            Pr = fill(NaN, size(P, 2))
            depthr = 0
            break
        end
    end

    return Pr, depthr
end
