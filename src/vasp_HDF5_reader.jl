# should probably go to AtomsIO.jl

using HDF5

h=h5open("../test/0002-VASP-MD-ARCHER2-P6Pb9Cu1O26H2-vaspout.h5")

# ├─ 📂 intermediate
# │  ├─ 📂 ion_dynamics
# │  │  ├─ 🔢 energies
# │  │  ├─ 🔢 energies_tags
# │  │  ├─ 🔢 forces
# │  │  ├─ 🔢 lattice_vectors
# │  │  ├─ 📂 magnetism
# │  │  │  ├─ 🔢 component_tags
# │  │  │  ├─ 🔢 moments
# │  │  │  └─ 🔢 orbital_tags
# │  │  ├─ 🔢 position_ions
# │  │  └─ 🔢 stress

read(h["results/positions/ion_types"])
#5-element Vector{String}:
read(h["results/positions/number_ion_types"])
#5-element Vector{Int32}:

read(h["intermediate/ion_dynamics/position_ions"])
#3×44×242 Array{Float64, 3}:

read(h["intermediate/ion_dynamics/lattice_vectors"])
#3×3×242 Array{Float64, 3}:


