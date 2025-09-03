using Ecosons
using CairoMakie, Statistics, LinearAlgebra
using Test 

@testset begin
        data = [1.0, NaN, 3.0, 5.0]
        m = nnmean(data)
        println("Mean (ignoring NaNs): ", m)

        t = 0:0.1:2π
        x = sin.(t)
        tp = 0:0.05:2π

        xp = triginterp(collect(t), x, collect(tp))
        println("Interpolated values: ", xp)

        x = [1.0, 2.0, 2.5, 100.0]  # outlier at the end
        μ, w = wmean(x)

        println("Weighted mean: ", μ)
        println("Weights: ", w)

        x = [1.0 10.0 5.0;
        2.0 12.0 6.0;
        3.0 14.0 7.0;
        100.0 100.0 100.0]  # outlier row

        μ, w = wmean(x)

        println("Weighted means per column: ", μ)
        println("Weights: ", w)

        data = [1.0 NaN 3.0;
                NaN 1.0 3.0]
        s = nnsum(data)
        println("Sum ignoring NaNs: ", s)


        X = [1.0, 2.0, 3.0, 4.0]
        Y = [2.1, 4.2, 6.1, 8.3]

        m, y0, r2 = linreg(X, Y)
        println("Slope: ", m)
        println("Intercept: ", y0)
        println("R²: ", r2)

        # Define the fitted line
        Xfit = range(minimum(X), maximum(X), length=100)
        Yfit = y0 .+ m .* Xfit

        # Plot
        f = Figure()
        ax = Axis(f[1, 1], xlabel="X", ylabel="Y", title="Linear Regression")

        scatter!(ax, X, Y, label="Data", color=:blue)
        lines!(ax, Xfit, Yfit, label="Fit: y = $(round(m, digits=2))x + $(round(y0, digits=2))", color=:red)

        axislegend(ax)
        display(f)

end
