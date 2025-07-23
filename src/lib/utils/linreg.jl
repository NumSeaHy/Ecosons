"""Iterative linear weighted least squares"""
function linreg(X::AbstractVector, Y::AbstractVector)
    chi2 = 1.0
    arw = zeros(length(X))

    for _ in 1:10
        w = chi2 ./ (chi2 .+ arw.^2)
        global Sw = sum(w)
        global Sx = dot(w, X)
        global Sy = dot(w, Y)
        global Sxx = dot(w, X .^ 2)
        global Syy = dot(w, Y .^ 2)
        global Sxy = dot(w, X .* Y)

        denom = Sw * Sxx - Sx^2
        global y0 = (Sxx * Sy - Sx * Sxy) / denom
        global m = (Sw * Sxy - Sx * Sy) / denom

        chi2 = y0^2 + (Syy + 2*m*Sxy - 2*y0*Sy + m^2*Sxx - 2*y0*m*Sx) / Sw
        arw = Y .- (y0 .+ m .* X)
    end

    r2 = ((Sw * Sxy - Sx * Sy)^2) / ((Sw * Sxx - Sx^2) * (Sw * Syy - Sy^2))
    return m, y0, r2
end

