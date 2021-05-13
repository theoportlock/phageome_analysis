# Analysis for oral/gut phageome

## Install packages with the following command
For R packages:
```
while read i; do Rscript -e "install.packages(\"$i\", repos=\"https://cloud.r-project.org\")"; done < R_requirements.txt
```

For python packages:
```
pip install -r python_requirements.txt
```


For python packages:

### Creating phage catalogue and quantification

##### Step 1: helper_scripts/create_catalogue_dataset.R
##### Step 2: helper_scripts/get_candidate_jumbophages.R
##### Step 3: helper_scripts/collate_functional_annotations.R
##### Step 4: helper_scripts/phage_quantification.R
