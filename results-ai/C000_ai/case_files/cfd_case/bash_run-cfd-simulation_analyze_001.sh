#!/bin/bash
. /home/dafoamuser/dafoam/loadDAFoam.sh
python script_plot_results.py -mode general_plot_residual -case_dir . -log_file log_simulation.txt >> log_plot_cfd.txt 2>&1
python script_plot_results.py -mode general_plot_function -case_dir . -log_file log_simulation.txt -tail_fraction 1.0 >> log_plot_cfd.txt 2>&1
python script_plot_results.py -mode wing_plot_flow_field -case_dir . -flow_field Cp -camera_scale 1.0 -var_lower -2.0 -var_upper 2.0 -var_ref 101325.0 -var_scaling 0.00015665448678031953 >> log_plot_cfd.txt 2>&1
python script_plot_results.py -mode wing_plot_flow_field -case_dir . -flow_field U -camera_scale 1.0 -var_lower -1.0 -var_upper 1.0 -var_ref 104.15661284815285 -var_scaling 0.009600926649351332 -field_label "(|U|-U0)/U0" >> log_plot_cfd.txt 2>&1
python script_plot_results.py -mode wing_plot_pressure_profile -case_dir . -time_step=-1 -mesh_file VTK/boundary.vtp -reference_pressure 101325.0 -pressure_coefficient_scale 6383.4749999999985 -var_lower -2.0 -var_upper 2.0 -wing_span=3.0 -spanwise_chords 1.0 1.0 1.0 -spanwise_x 0.0 0.0 0.0 -spanwise_fractions 0.1 0.5 0.9 >> log_plot_cfd.txt 2>&1
python script_plot_results.py -mode wing_plot_spanwise_variable -case_dir . -vtp_file VTK/boundary.vtp -angle_of_attack 5.4 >> log_plot_cfd.txt 2>&1
python script_workflow_helpers.py write-cfd-analysis --log-file log_simulation.txt --output-file cfd_analysis_metrics.json
