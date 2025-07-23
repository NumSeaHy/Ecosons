"""
Estimates the local slope of a signal `sH` with respect to `sX` using robust linear regression 
within a sliding window of radius `ll`.

This function computes the slope (`mr`) at each index of `sH` by fitting a weighted least-squares
line to a local neighborhood. The weights are iteratively refined to reduce the influence of outliers.

# Arguments
- `sH::AbstractVector`: Signal values (e.g., depth or intensity).
- `sX::AbstractVector`: Corresponding X-axis values (e.g., range or distance).
- `ll::Int`: Half-window size for the local regression; total window size is `2ll + 1`.

# Returns
- `ssl::Vector{Float64}`: Vector of local slope estimates for each index in `sH`.

# Method
For each index `n`, a robust regression is performed over the window `[n - ll, n + ll]`.
An iterative process (20 steps) adjusts weights inversely proportional to residual errors,
to reduce the effect of outliers and improve slope reliability.
"""
function rangeSlope(sH::AbstractVector, sX::AbstractVector, ll::Int)
    N = length(sH)
    ssl = zeros(N)
    
    for n in 1:N
        rg = max(1, n - ll):min(n + ll, N)
        lr = length(rg)
        w = fill(1.0 / lr, lr)  # initial uniform weights
        
        iter = 1
        while iter <= 20
            dx = sX[rg] .- sX[n]
            sx = sum(w .* dx)
            sy = sum(w .* sH[rg])
            sxx = sum(w .* dx .* dx)
            sxy = sum(w .* dx .* sH[rg])
            global mr = (sxy - sx * sy) / (sxx - sx^2)
            avg = sy - mr * sx
            residuals = sH[rg] .- (mr .* dx .+ avg)
            w = 1.0 ./ (1 .+ residuals.^2)
            w /= sum(w)
            iter += 1
        end
        
        ssl[n] = mr
    end
    
    return ssl
end
