#!/bin/bash

pipeline=$1
environment=$2

working_dir=/workspaces/ytt-lab/jinja-example
outputs_dir=/workspaces/ytt-lab/outputs
#
# Use Spruce to Merge and Create Pipeline Inputs File 
# known as data.values file to ytt
#

yasha \
# Include All task directories
-I $working_dir/tasks \

# Output file 
-o $outputs_dir/pipeline.out.yml \

# Defaults appleid to all pipelines
-v $working_dir/pipeline-vars/defaults.yml \
# Vars specific to this pipeline
-v $working_dir/pipeline-vars/$pipeline.yml \

# Vars Specific to all environments
-v $working_dir/environments/common/vars.yml \
# Vars specific to this environment
-v $working_dir/environments/$environment/vars.yml \

# pipeline template
$working_dir/pipelines/$pipeline.yml                     
