#!/bin/bash
. /home/dafoamuser/dafoam/loadDAFoam.sh
python script_generate_mesh.py -airfoil_profiles naca0012 naca0012 -chords 1 1 -spans 3 -sweeps 0 -dihedrals 0 -twists 0 -surf_mesh_cells=5367 -blunt_te=0.01 -trailing_edge_shape=rounded -tip_cluster=0.1 -le_cluster=0.1 -te_cluster=0.1 -farfield_scale=10.0 -n_layers=68 -d0=-1.0 -y_plus=70.0 -mach_number=0.3 -reynolds_number=5000000.0 -diffusion_sweeps=10 -neighbor_rings=10 -sym_axis=y -sym_decay=-1.0 > log_mesh.txt 2>&1
createPatch -overwrite >> log_mesh.txt 2>&1
renumberMesh -overwrite >> log_mesh.txt 2>&1
rm -rf VTK >> log_mesh.txt 2>&1
foamToVTK -latestTime -patches '(wing sym)' -one-boundary >> log_mesh.txt 2>&1
mv VTK/*/boundary.vtp VTK/ >> log_mesh.txt 2>&1 || true
touch run_finished.pid
