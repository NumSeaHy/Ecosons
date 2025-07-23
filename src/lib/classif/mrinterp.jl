using DSP
using ImageFiltering

function mrinterp(x, y, z, dxy, slev; xmin=nothing, xmax=nothing, ymin=nothing, ymax=nothing)
    # Determine grid extents if not provided
    xmin = xmin === nothing ? minimum(x) : xmin
    xmax = xmax === nothing ? maximum(x) : xmax
    ymin = ymin === nothing ? minimum(y) : ymin
    ymax = ymax === nothing ? maximum(y) : ymax

    dx = xmax - xmin
    wa = ceil(Int, dx / dxy)
    w = nextpow(2, wa)
    xmin -= (w - wa) * dxy / 2
    xmax = xmin + w * dxy
    Nlx = Int(log2(w))

    dy = ymax - ymin
    ha = ceil(Int, dy / dxy)
    h = nextpow(2, ha)
    ymin -= (h - ha) * dxy / 2
    ymax = ymin + h * dxy
    Nly = Int(log2(h))

    # Filter points inside bounding box
    inside = (xmin .<= x) .& (x .<= xmax) .& (ymin .< y) .& (y .<= ymax)
    x, y, z = x[inside], y[inside], z[inside]

    Nl = min(Nlx, Nly)
    bl = min(w, h)

    # Compute grid cell indices for each point
    i = 1 .+ floor.(Int, (ymax .- y) ./ dxy)
    j = 1 .+ floor.(Int, (x .- xmin) ./ dxy)
    ij = i .+ h .* (j .- 1)

    # Initialize projection matrices
    map0N = zeros(Int, h, w)
    map0S = zeros(Float64, h, w)

    for n in eachindex(z)
        idx = ij[n]
        map0N[idx] += 1
        map0S[idx] += z[n]
    end
    println("Non-zero map0N: ", count(map0N .> 0))
    println("Min/max of map0S: ", extrema(map0S[map0N .> 0]))
    # Threshold to exclude sparse cells
    nmin = 5
    while sum(map0N .> nmin) > 0.99 * sum(map0N .> 0)
        nmin += 1
    end

    map0S[map0N .>= nmin] ./= map0N[map0N .>= nmin]
    map0S[map0N .< nmin] .= 0
    map0N .= map0N .>= nmin

    mapa0 = fill(NaN, size(map0S))
    mapa0[map0N .> 0] .= map0S[map0N .> 0]

    # Keep original full-resolution maps for block-averaging
    #= map0N_orig = copy(map0N)
    map0S_orig = copy(map0S) =#

    b = float(bl)
    mapaN = zeros(Float64, h, w)
    mapaS = zeros(Float64, h, w)
    maplS = zeros(Float64, h, w)  # fallback initialization, or zeros(Float64, h, w)
    maplN = zeros(Float64, h, w)
    for l in 0:Nl
        println("Level $l (b = $b)")
        b_int = Int(b)
        ni = div(h, b_int)
        nj = div(w, b_int)

        maplS = zeros(Float64, ni, nj)
        maplN = zeros(Int, ni, nj)

        if l <= Nl - slev
            for i in 1:ni
                for j in 1:nj
                    i1 = 1 + (i - 1) * b_int
                    i2 = min(i * b_int, size(map0N, 1))
                    j1 = 1 + (j - 1) * b_int
                    j2 = min(j * b_int, size(map0S, 2))

                    maplN[i, j] = sum(@view map0N[i1:i2, j1:j2])
                    maplS[i, j] = sum(@view map0S[i1:i2, j1:j2])
                end
            end
        end

        if l > 0
            m = maplN .> 0
            #= mapaN = zeros(Float64, size(maplN))
            mapaS = zeros(Float64, size(maplS)) =#
            mapaN[m] .= maplN[m]
            mapaS[m] .= maplS[m]
            m .= .!m

            mK = [0.0 1 0; 1 0 1; 0 1 0]
            mK ./= sum(mK)
            
            kernel = centered(mK)
            cmapaM = imfilter(mapaN .> 0, kernel, Pad(:replicate))
            cmapaN = imfilter(mapaN, kernel, Pad(:replicate))
            cmapaS = imfilter(mapaS, kernel, Pad(:replicate))

            m_inv = m .& (cmapaM .> 0)
            maplN[m_inv] = round.(Int, cmapaN[m_inv] ./ cmapaM[m_inv])
            maplS[m_inv] = cmapaS[m_inv] ./ cmapaM[m_inv]
            println("Level $l: non-zero indices in maplN = ", findall(!=(0), maplN))
        end

        if l < Nl 
            b /= 2
            mapaS = dupl2(maplS) ./ 4
            mapaN = dupl2(maplN) ./ 4
            #map0S, map0N = mapaS, mapaN
        end
    end

    mapa = fill(NaN, size(maplS))
    mapa[maplN .> 0] .= maplS[maplN .> 0] ./ maplN[maplN .> 0]

    if size(mapa) != size(mapa0)
        @warn "mapa0 and mapa have different sizes"
    end

    return mapa, xmin, xmax, ymin, ymax, mapa0
end

# Helper: duplicate each value into a 2×2 block
# Helper: duplicate each value into a 2×2 block
function dupl2(a)
    ha, wa = size(a)
    b = Array{eltype(a)}(undef, 2ha, 2wa)
    @inbounds for i in 1:ha
        for j in 1:wa
            v = a[i, j]
            ii = 2i - 1
            jj = 2j - 1
            b[ii, jj] = v
            b[ii+1, jj] = v
            b[ii, jj+1] = v
            b[ii+1, jj+1] = v
        end
    end
    return b
end