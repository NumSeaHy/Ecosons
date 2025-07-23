
# EcoSons Julia Package Overview

**Author:** Carlos Vázquez Monzón  
**Project:** Port of the EcoSons project from Octave to Julia

---

## 📦 Project Structure

- **Main Module:** `Ecosons.jl`  
- **Purpose:** Transition Octave-based sonar data processing into a more efficient Julia implementation.

---

## 🔄 Key Differences from Octave

- **GUI Replacement:** Octave’s GUI replaced with JSON parsing in Julia.
- **Data Types:** Octave’s `cell` types replaced by Julia’s `structs`.
- **File Formats:** Octave’s `.mat` → Julia’s `.jld2`.

---

## ✨ New Julia Features

### `interp1.jl`
- Julia’s custom interpolation function, mimicking Octave’s `interp1`.
- Supports `linear` and `nearest` methods, optional extrapolation.

### `BathymetryCrosses`
- Optimized bathymetry intersection algorithm.
- Uses grid indexing and dynamic arrays.
- Execution speed:  
  - Octave: 3 min 53 s  
  - Julia (non-optimized): 20 s  
  - Julia (optimized): 2 s  

### Transect Animations
- Function: `plot_transects`
- Features: optional 3D plots, GIF generation, custom frame rate.

---

## 🧪 Other Improvements

- Comprehensive docstrings and documentation.
- Extensive testing coverage.
- Enhanced plotting capabilities: `plot_ping`, `plot_bathymetry_line`, `plot_data_from_file`.
- General performance improvements across all functions.



**Thank you!**
