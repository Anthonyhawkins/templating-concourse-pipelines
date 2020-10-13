#!/bin/bash

pipeline=$1
environment=$2

working_dir=/workspaces/ytt-lab/ytt-example

#
# Use Spruce to Merge and Create Pipeline Inputs File 
# known as data.values file to ytt
#

echo "#@data/values" > data_vaules.yml
echo "---" >> data_vaules.yml

spruce merge \
$working_dir/pipeline-vars/defaults.yml \
$working_dir/pipeline-vars/$pipeline.yml \
>> data_vaules.yml

#
# Use YTT to combine data.values with pipeline config and task configs.
#
ytt -f $working_dir/pipelines/$pipeline.yml \
    -f $working_dir/tasks/ \
    -f data_vaules.yml > pipeline.spruce.yml

#
# Use spruce again to inject ENV variables and finalize config
#

#spruce
spruce merge pipeline.spruce.yml > pipeline.yml

#
# Run Fly Set pipeline 
#