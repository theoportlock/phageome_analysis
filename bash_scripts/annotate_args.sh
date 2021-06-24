#!/bin/bash
#SBATCH --partition=shared
#SBATCH --mem=150G
#SBATCH --time=02:00:00
#SBATCH --job-name=blastp_card

module load apps/blast+
blastp -db ../db/CARD_3.0.0/protein_fasta_protein_homolog_model.fasta -query ../data/jumbophage_contigs_translations.faa -out ../data/jumbophage_proteins_card.out -outfmt 4 -num_threads 2 -evalue 1e-5
