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


function getAverageHit(sonar_data, nearF)
    # Calculate the near-field index (no depth shallower than nearF)
    knf = 2 * floor(Int, nearF / (sonar_data.HS[1].soundVelocity * sonar_data.HS[1].sampleInterval))
    lgt = size(sonar_data.P, 2)

    hit = fill(NaN, size(sonar_data.P, 1))

    for k in 1:size(sonar_data.P, 1)
        pPk = 10 .^ (sonar_data.P[k, knf:lgt] / 10)
        pPkr = pPk .* collect(1:(lgt - knf + 1))
        hit[k] = sum(skipmissing(pPkr)) / sum(skipmissing(pPk))
        if isnan(hit[k])
            hit[k] = 0
        end
    end

    for k in 1:size(sonar_data.P, 1)
        pPk = 10 .^ (sonar_data.P[k, knf:lgt] / 10)
        lk = min(round(Int, 1.5 * hit[k]), length(pPk))
        llk = max(knf, floor(Int, 0.5 * hit[k]))
        if lk > 0
            pPkr = pPk[1:lk] .* collect(1:lk)
            hit[k] = sum(skipmissing(pPkr)) / sum(skipmissing(pPk[1:lk]))
            if isnan(hit[k])
                hit[k] = 0
            end
        end
    end

    hit .+= (knf - 1)
    hit = round.(hit)
    return hit
end


h = getAverageHit(sonar_data, 5)
nearF = 5
knf = 2 * floor(Int, nearF / (sonar_data.HS[1].soundVelocity * sonar_data.HS[1].sampleInterval))
pP = sonar_data.P[:, knf:end]
