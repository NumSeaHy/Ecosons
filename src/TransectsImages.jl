using CairoMakie
ranges = [range(1, 7), range(8, 30), range(31, 42)]
aux = 1
for i in ranges
    latitudes = [baths[j].latitude for j in i]
    longitudes = [baths[j].longitude for j in i]
    fig = plot_transects(latitudes, longitudes)
    save("./assets/transects_images/transects_group" * string(aux) * ".png", fig)
    aux += 1
end

latitudes = [baths[i].latitude for i in group]
longitudes = [baths[i].longitude for i in group]
fig = plot_transects(latitudes, longitudes)
save("transects_group"*".png", fig)