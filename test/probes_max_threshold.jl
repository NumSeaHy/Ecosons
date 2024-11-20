using Revise
includet("../src/EA400Load.jl")
using .EA400Load
fn = "./data/L0019-D20140719-T111533-EA400.raw"
P, Q, HS = fmt_simradRAW(fn)
name = extract_identifier(fn)

channel = 1
P1 = P[channel]
Q1 = Q[channel]
HS1 = HS[channel]

sonar_data = SonarData(name, P1, Q1, HS1)

function getFirstHit(sonar_data, nearF, ndB=30, nndB=60)
    # near field index
    knf = 2 * floor(Int, nearF / (sonar_data.HS[1].soundVelocity * sonar_data.HS[1].sampleInterval))
    pP = sonar_data.P[:, knf:end]

    # Initialize hits array
    hit = zeros(Int, size(sonar_data.P, 1))

    for p in 1:size(sonar_data.P, 1)
        # Find the maximum value in the ping and his position
        maxP = maximum(pP[p, :])
        hit[p] = argmax(pP[p, :])
        
        # Search for the first hit
        for k in reverse(1:hit[p])
            if pP[p, k] >= maxP - ndB
                hit[p] = k
            elseif pP[p, k] < maxP - nndB
                break
            end
        end
    end

    return hit .+ (knf - 1)  # Correct index with near field index
end

h = getFirstHit(sonar_data, 10)
nearF = 5
knf = 2 * floor(Int, nearF / (sonar_data.HS[1].soundVelocity * sonar_data.HS[1].sampleInterval))
pP = sonar_data.P[:, knf:end]
