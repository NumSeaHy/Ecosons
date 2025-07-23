"""
Computes the weighted mean value of a vector using as weigths the Fisher scores
(ML estimator assuming Gaussian distribution)
"""
function wmean(x::AbstractVector)
    μ = mean(x)
    σ² = var(x, corrected=true)

    if σ² == 0
        return μ, ones(length(x)) ./ length(x)  # Uniform weights
    end

    # Fisher scores (magnitude)
    scores = abs.((x .- μ) ./ σ²)

    # Avoid zero weights
    if all(scores .== 0)
        weights = ones(length(x)) ./ length(x)
    else
        weights = scores ./ sum(scores)
    end

    wmean = sum(weights .* x)
    return wmean, weights
end

function wmean(x::AbstractMatrix; dims::Int=1)

    μ = mean(x; dims=dims)                      # 1×n
    σ² = var(x; dims=dims, corrected=true)      # 1×n

    # Handle near-zero variance
    σ² = max.(σ², eps())

    # Fisher scores: (x - μ) / σ²
    scores = abs.((x .- μ) ./ σ²)            # m×n

    # Normalize weights along dims=1 (i.e., per column)
    weights = scores ./ sum(scores; dims=dims)  # m×n

    # Weighted mean: sum(weights .* x) per column
    wmean = sum(weights .* x; dims=dims)        # 1×n

    return dropdims(wmean; dims=dims), weights
end 