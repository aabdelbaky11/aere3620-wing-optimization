#!/bin/bash
. /home/dafoamuser/dafoam/loadDAFoam.sh
checkMesh >> log_mesh.txt 2>&1 || exit 200
python script_plot_results.py -mode wing_plot_mesh -case_dir . -mesh_file VTK/boundary.vtp -geometry_file wing.stl -camera_scale 1.0 > log_mesh_plot.txt 2>&1
python script_workflow_helpers.py write-mesh-analysis --log-file log_mesh.txt --metrics-file mesh_analysis_metrics.json --analysis-file mesh_analysis.json
