using AtomsIO
using AtomsIOPython  # Enable python-based parsers as well

t = load_trajectory("P6Pb9Cu1O26H2.vasp_md.traj") # traj -> ASE traj via AtomsIOPython

filter( a -> a.atomic_symbol == :Cu, t[2].particles)


