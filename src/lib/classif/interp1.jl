function interp1(x::AbstractVector, y::AbstractVector, xi::AbstractVector; method::String="linear", extrap=nothing)
    # Ensure x, y, xi are vectors
    x = collect(x)
    y = collect(y)
    xi = collect(xi)

    nx = length(x)
    ny = length(y)

    if nx < 2 || ny < 2
        error("interp1: minimum of 2 points required")
    end

    # Sort x (and y accordingly) if not sorted
    if !issorted(x)
        p = sortperm(x)
        x = x[p]
        y = y[p]
    end

    # Default extrapolation value for numeric types
    if extrap === nothing
        extrap = eltype(y) <: Complex ? NaN + im*NaN : NaN
    end

    # Handle repeated x values (jumps)
    jumps = (x[1:end-1] .== x[2:end])
    have_jumps = any(jumps)
    if have_jumps && !(method in ("nearest", "linear"))
        error("interp1: discontinuities not supported for method '$method'")
    elseif have_jumps
        # For nearest and linear, warn if multiple discontinuities
        if any(jumps[1:end-2] .& jumps[2:end-1])
            @warn "interp1: multiple discontinuities at the same X value"
        end
    end

    # Interpolation
    yi = similar(xi, eltype(y))

    if method == "nearest"
        # Create breakpoints for nearest interpolation
        breaks = vcat(x[1], (x[1:end-1] .+ x[2:end]) ./ 2, x[end])
        # Find index for each xi
        idxs = searchsortedlast.(Ref(breaks), xi)
        # Clamp indices
        idxs = clamp.(idxs, 1, length(y))
        yi .= y[idxs]

    elseif method == "linear"
        # Remove zero-length intervals if jumps present
        if have_jumps
            mask = .!jumps
            xx = x[mask]
            yy = y[mask]
        else
            xx = x
            yy = y
        end

        # For each xi, find interval and interpolate linearly
        for i in eachindex(xi)
            if xi[i] < minimum(xx) || xi[i] > maximum(xx)
                yi[i] = extrap
            else
                idx = searchsortedlast(xx, xi[i])
                if idx == length(xx)
                    idx -= 1
                end
                x1, x2 = xx[idx], xx[idx+1]
                y1, y2 = yy[idx], yy[idx+1]
                t = (xi[i] - x1) / (x2 - x1)
                yi[i] = (1 - t)*y1 + t*y2
            end
        end

    else
        error("interp1: unsupported method '$method'. Use 'nearest' or 'linear'")
    end

    return yi
end
