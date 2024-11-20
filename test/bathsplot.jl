using Serialization
using PlotlyJS

matrix_baths = deserialize("./data/baths_3D.bin")
group = 2
z_data = matrix_baths[group]

data = surface(
    z=z_data,
    colorscale="Viridis",
    colorbar=attr(
      orientation="h",
      x=0.5,  
      y=-0.3,   # Center the colorbar along the y-axis
      len=0.5, # Adjust the length of the colorbar
      thickness=20,  # Adjust the thickness of the colorbar
      showlegend=true
  )
)

# Define the layout with adjusted legend and axis labels
layout = Layout(
    width = 600,
    height = 600,
    scene = attr(
        xaxis = attr(title = "Longitude", showticklabels = false),
        yaxis = attr(title = "Latitude", showticklabels = false),
        zaxis = attr(title = "Depth")
    ),
    legend=attr(
        orientation="h",
        x = -0.25,  # Adjust the x position of the legend
        y = -0.1,
        showlegend=true
    ) 
    
)

plot(data, layout)