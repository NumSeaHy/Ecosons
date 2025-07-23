using ..DataTypes:GPSDataLowrance

function gpsLowrance(X::UInt32, Y::UInt32, T::UInt32)::GPSDataLowrance
    Sm = 6356752.3142      # Earth's radius (approximate)
    dg = 57.2957795132     # 180 / π

    # Decode X (longitude)
    X_masked = X & 0x00FFFFFF
    if (X & 0x00800000) != 0
        X_masked = Float64(X) - (256^3 - 1)
    else
        X_masked = Float64(X_masked)
    end

    # Decode Y (latitude)
    Y_masked = Y & 0x00FFFFFF
    if (Y & 0x00800000) != 0
        Y_masked = Float64(Y) - (256^3 - 1)
    else
        Y_masked = Float64(Y_masked)
    end

    latitude = dg * (2 * atan(exp(Y_masked / Sm)) - π / 2)
    longitude = dg * X_masked / Sm
    time = T / 1000.0

    return GPSDataLowrance(time, latitude, longitude)
end
