### Creating phage catalogue and quantification

##### Step 1: helper_scripts/create_catalogue_dataset.R
##### Step 2: helper_scripts/get_candidate_jumbophages.R
##### Step 3: helper_scripts/collate_functional_annotations.R
##### Step 4: helper_scripts/phage_quantification.R

### In silico pipelines
- Generating the phage catalogue: bash_scripts/commands.txt
- Function annotation with HMMs: bash_scripts/protein_function_annotation.sh
- Identifying tRNA using ARAGORN: bash_scripts/extract_trna_from_jumbophages.sh
- Identifying ARGs using CARD database: bash_scripts/annotate_args.sh
- Other data cleaning/wraggling: helper_scripts

#### To Do
- Dependency scripts in commands.sh
- Command for vConTACT
- data/virsorter_positive.fasta file

### Data analysis and visualisation
- Statistical analysis and data visualisation: phage_analysis.R

### Install packages with the following command
For R packages:
```
while read i; do Rscript -e "install.packages(\"$i\", repos=\"https://cloud.r-project.org\")"; done < R_requirements.txt
```

For python packages:
```
pip install -r python_requirements.txt
```
