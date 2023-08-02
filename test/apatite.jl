using AtomsIO
using AtomsIOPython  # Enable python-based parsers as well

using SMASH

t = load_trajectory("P6Pb9Cu1O26H2.vasp_md.traj") # traj -> ASE traj via AtomsIOPython

Cus=filter( a -> a.atomic_symbol == :Cu, t[2].particles)
Pbs=filter( a -> a.atomic_symbol == :Pb, t[2].particles)

using LinearAlgebra
[norm(Pb.position-Cus[1].position) for Pb in Pbs]
# doesn't appear to use minimum image convention - just Angstrom distances within unit cell

# something like this, but tripping over Unitful
SMASH.minimd(Pbs[1].position,Cus[1].position,t[1].bounding_box)

# OK, let's look at the minimum volume ellipsoid alog

# matrix of positions
points = [Unitful.ustrip(a.position) for a in Pbs] |> hcat

# chokes as the points are now unitless but still some kinda SVector
SMASH.minimumVolumeEllipsoid(points)

# would be reaely good to have this in Pluto, rather than tmux and ssh :^)


