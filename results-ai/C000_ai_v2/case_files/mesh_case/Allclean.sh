#!/bin/bash

echo "Cleaning..."
rm -rf 0
rm -rf postProcessing
rm -rf constant/polyMesh/ constant/triSurface/* constant/extendedFeatureEdgeMesh dynamicCode VTK
rm -rf *.bin *.info *.dat *.xyz *.stl *.jpeg *.png reports *.txt *.hst *.igs *.msh *.iges *.bdf *.dcel
rm -rf processor* 0.00*
rm -rf .dafoam_run_finished
rm -rf plots/*
rm -rf {1..9}*
