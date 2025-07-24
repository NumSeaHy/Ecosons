# EcoSons Configuration Parameters

This document describes the JSON configuration parameters used in the EcoSons Julia package for sonar data processing.

---

## Configuration Arguments

### `data_dir`
- **Description:** Directory containing raw sonar data files (`.raw`).
- **Example:** `"../data/EA400"`

### `channel`
- **Description:** Channel number to process.
- **Type:** Integer
- **Example:** `1`

### `transect`
- **Description:** Selected transect index or ID.
- **Type:** Integer
- **Example:** `3`

### `bottom_detection`
Parameters controlling bottom detection in sonar data:
- `sel` (Integer): Selection mode for detection.
- `nF` (Float): Frequency filter length.
- `smoothR` (Integer): Range smoothing window size.
- `smoothS` (Integer): Along-track smoothing window size.
- `ndB` (Integer): Decibel threshold.
- `nndB` (Integer): Secondary decibel threshold.
- `do_smoothing` (Boolean): Apply smoothing or not.

- See [`compute_bottom`](https://github.com/NumSeaHy/ecosons_julia/blob/my-branch/src/BottomDetection.jl#LXX) for details.

### `echobottom`
Settings for echobottom output and plotting:
- `output_file` (String): Path for saving processed echobottom data.
- `plot_echobottom`:
  - `pings` (Nullable): Pings range for plotting.
  - `bins` (Nullable): Bins range for plotting.

- See [`plot_echobottom`](https://github.com/NumSeaHy/ecosons_julia/blob/my-branch/src/Plotting.jl#LXX).

### `bathymetry`
Parameters for bathymetry processing:
- `output_file` (String): Export path.
- `n_step` (Integer): Step size in processing.
- `e_time` (Boolean): Consider elapsed time.

- See [`process_bathymetry`](https://github.com/NumSeaHy/ecosons_julia/blob/my-branch/src/Bathymetry.jl#LXX).

### `JLD2_dir`
Paths for saving JLD2 data files:
- `data`: Sonar data.
- `bath`: Bathymetry data.

### `tides`
- `dir`: Path to tide data file.

### `classification`
Settings for classification:
- `export_file`: Output path.
- `nchan`: Number of channels.
- `depthInf`: Depth threshold.
- `npings`: Number of pings per window.
- `dnpings`: Ping step.
- `depthRef`: Reference depth.

- See [`classify_sonar_data`](https://github.com/NumSeaHy/ecosons_julia/blob/my-branch/src/Classification.jl#LXX).

### `transects`
Transect-related parameters:
- `use_utm`: Use UTM coordinates.
- `sel`: Transect selection.
- `plot`:
  - `save_dir`: Directory for plots.
  - `is3d`: 3D plotting toggle.
  - `make_gif`: Create GIF.
  - `framerate`: GIF frame rate.
- `export`:
  - `file`: Export path.
  - `n_step`: Export step.

- See [`plot_transects`](https://github.com/NumSeaHy/ecosons_julia/blob/my-branch/src/Transects.jl#LXX).

### `slopes`
Slope calculation parameters:
- `krad`: Kernel radius.
- `export_file`: Export path.
- `srad`: Search radius.
- `nrsp`: Number of samples.

- See [`calculate_slopes`](https://github.com/NumSeaHy/ecosons_julia/blob/my-branch/src/Slopes.jl#LXX).

### `bathycross`
Bathymetry cross-section parameters:
- `point_subsampling`: Subsampling rate.
- `useUTM`: Use UTM coordinates.
- `export_file`: Export path.

- See [`bathymetry_cross_section`](https://github.com/NumSeaHy/ecosons_julia/blob/my-branch/src/BathymetryCrosses.jl#LXX).

---

## Related Functions

- [`load_sonar_data`](https://github.com/NumSeaHy/ecosons_julia/blob/my-branch/src/LoadData.jl#LXX) — Load and parse raw sonar files.
- [`compute_bottom`](https://github.com/NumSeaHy/ecosons_julia/blob/my-branch/src/BottomDetection.jl#LXX) — Detect seabed bottom.
- [`plot_echobottom`](https://github.com/NumSeaHy/ecosons_julia/blob/my-branch/src/Plotting.jl#LXX) — Visualize echobottom data.
- [`export_echobottom`](https://github.com/NumSeaHy/ecosons_julia/blob/my-branch/src/Export.jl#LXX) — Export processed data to file.

---

*Note:* Replace `#LXX` with the actual line number or function anchor in the code files for precise linking.

---

**Thank you for using EcoSons!**
