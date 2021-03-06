#!/bin/bash

# FLYCOP 
# Author: Beatriz García-Jiménez
# April 2018

# call: FLYCOPanalyzingResults_coGrowth4Ecoli.sh 1 V2 'ratioGRavgGR' 500

domainName='coGrowth4Ecoli'

id=$1 # '20', '21', ...
templateID=$2 # 'V1' 'V2' 'V5' ...
fitness=$3
nRuns=$4

currDir=`pwd`
dataAnalysisDir=${currDir}/${domainName}_scenario${id}_FLYCOPdataAnalysis
mkdir $dataAnalysisDir

seed=123
cd smac-output/${domainName}_confFLYCOP_scenario_v${id}/state-run${seed}

# 1.- Get summary statistics file $nRuns SMAC configurations
tail -n${nRuns} runs_and_results-it*.csv | awk -F, '{print NR","1-$4}' > $dataAnalysisDir/fitness.csv
paste -d, paramstrings-it*.txt $dataAnalysisDir/fitness.csv > $dataAnalysisDir/paramstrings_withFitness.csv
echo "ec1\tec2\tec3\tec4\targ\tlys\tmet\tphe\tfitness" > $dataAnalysisDir/tableParamWithFitness.csv
cut -d, -f1-8,10 $dataAnalysisDir/paramstrings_withFitness.csv | awk 'BEGIN{FS="[=,]"} {print $2"\t"$4"\t"$6"\t"$8"\t"$10"\t"$12"\t"$13}' | sed "s/'//g" | sed "s/-999999999/0/">> $dataAnalysisDir/tableParamWithFitness.csv
egrep "WARN.*Result of algorithm run|ERROR.*The following algorithm call failed" ../log-warn${seed}.txt | awk -F'Result of algorithm run: ' '{if($2==""){print "X,X,X,1,X,X,1"}else{print $2}}' | cut -d, -f4,7 | awk -F, '{print 1-$1","$2}' > $dataAnalysisDir/avgfitnessAndStdev.txt
# Retrieve configuration
cd ..
param1=`tail log-run${seed}.txt | egrep "p1_" | awk -F'p1_' '{print $2}' | cut -d' ' -f2 | sed "s/'//g"`
param2=`tail log-run${seed}.txt | egrep "p1_" | awk -F'p1_' '{print $2}' | cut -d' ' -f4 | sed "s/'//g"`
param3=`tail log-run${seed}.txt | egrep "p1_" | awk -F'p1_' '{print $2}' | cut -d' ' -f6 | sed "s/'//g"`
param4=`tail log-run${seed}.txt | egrep "p1_" | awk -F'p1_' '{print $2}' | cut -d' ' -f8 | sed "s/'//g"`
param5=`tail log-run${seed}.txt | egrep "p1_" | awk -F'p1_' '{print $2}' | cut -d' ' -f10 | sed "s/'//g"`
param6=`tail log-run${seed}.txt | egrep "p1_" | awk -F'p1_' '{print $2}' | cut -d' ' -f12 | sed "s/'//g"`
param7=`tail log-run${seed}.txt | egrep "p1_" | awk -F'p1_' '{print $2}' | cut -d' ' -f14 | sed "s/'//g"`
param8=`tail log-run${seed}.txt | egrep "p1_" | awk -F'p1_' '{print $2}' | cut -d' ' -f16 | sed "s/'//g"`
echo "Optimal consortium configuration found: " $param1 $param2 $param3 $param4 $param5 $param6 $param7 $param8
cd ../..

# 2.- Move configurations collection file to data analysis folder
mv smac-output/${domainName}_PlotsScenario${id}/ $dataAnalysisDir/
rm -Rf smac-output/
cd $dataAnalysisDir
mv ${domainName}_PlotsScenario${id}/configurationsResults* configurationsResults_Scenario${id}.txt
sort -k3 -r configurationsResults_Scenario${id}.txt | uniq > configurationsResults_Scenario${id}_sorted.txt 
rm configurationsResults_Scenario${id}.txt
cd ..

# 3.- R script to build scatterplot and correlations files
Rscript --vanilla ../Scripts/dataAnalysisPlotsAndTables_generic_single.r $domainName $id $fitness

# 4.- Generar un test individual, con el mismo nº de scenario (tengo que hacer trozo script python)
cp -p -R coGrowth4Ecoli_TemplateOptimizeConsortium${templateID} coGrowth4Ecoli_scenario${id}_optimalConfiguration
cd coGrowth4Ecoli_scenario${id}_optimalConfiguration
python3 -W ignore ../../Scripts/coGrowth4Ecoli_individualTestFLYCOP.py $param1 $param2 $param3 $param4 $param5 $param6 $param7 $param8 $fitness

cd $currDir
