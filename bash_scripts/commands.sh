#Assemble contigs
spades.py -k21,33,55 --only-assembler --meta <your reads> -o spades_output

#Rename and pool contigs
for i in $(ls /home/victoria/upload/*/*.fasta); do k=$(echo $i | cut -d '/' -f 6 | sed -e 's/_scaffolds.fasta//'); cat $i | sed -e "s/>NODE/>"$k"_NODE/g" >> all.fasta; done
perl ~/scripts/removesmalls.pl 3000 all.fasta > all_3000.fasta

#Make contigs non-redundant
makeblastdb -in all_3000.fasta -dbtype nucl
nohup blastn -db all_3000.fasta -query all_3000.fasta -evalue 1e-20 -word_size 100 -max_target_seqs 10000 -outfmt '6 qseqid sseqid pident length qlen slen evalue qstart qend sstart send' -num_threads 10 -out contigs3000_blastall_outfmt6.txt &
sh contigs_redundancy_removal_largefile.sh contigs3000_blastall_outfmt6.txt 90 0.9 all_3000.fasta

#Run HMM search against pVOGs with redundant contigs
nohup prodigal -i all_3000.fasta -a translations_all_3000.faa -p meta >> prodigal_out.txt &
hmmscan -E 0.00001 --tblout all_pvogs_hmm_tblout.txt -o all_pvogs_out.txt --cpu 20 /home/tom/pvogs/AllvogHMMprofiles/all_vogs.hmm translations_all_3000.faa &

#Process Virsorter predictions run by Victoria
for i in $(ls *-signal.csv); do k=$(echo $i | cut -d "_" -f 1); echo $k; grep 'VIRSorter_' < $i | cut -d ',' -f 1 | sed -e 's/_cov_\(.*\)_/\_cov_\1./g' -e 's/-circular//g' -e 's/VIRSorter_//g' | sed -e "s/NODE/"$k"_NODE/g" >> virsorter_positive.ids; done
pullseq -i ../all_3000.fasta -n virsorter_positive.ids > virsorter_positive.fasta
rm virsorter_positive.ids
grep '>' virsorter_positive.fasta | tr -d '>' > virsorter_positive.ids

#Remove redundancy
makeblastdb -in virsorter_positive.fasta -dbtype nucl
nohup blastn -db virsorter_positive.fasta -query virsorter_positive.fasta -evalue 1e-20 -max_target_seqs 10000 -outfmt '6 qseqid sseqid pident length qlen slen evalue qstart qend sstart send' -num_threads 10 -out virsorter_positive_blastall_outfmt6.txt &
sh ~/scripts/contigs_redundancy_removal_v1.5.sh virsorter_positive_blastall_outfmt6.txt 90 0.9 virsorter_positive.fasta

#Search for pVOGs
nohup prodigal -i virsorter_positive.fasta -a translations_virsorter_contigs.faa -p meta >> prodigal_out.txt &
nohup hmmscan -E 0.00001 --tblout all_pvogs_hmm_tblout.txt -o all_pvogs_out.txt --cpu 20 /home/tom/pvogs/AllvogHMMprofiles/all_vogs.hmm translations_virsorter_contigs.faa &
awk '{print $3}' all_pvogs_hmm_tblout.txt | sort | uniq | grep -o '^.*_' | sed -e 's/_$//' | sort | uniq -c > pvogs_counts_per_contig.txt

#Demovir familiy prediction
nohup bash ~/Demovir/demovir.sh translations_virsorter_contigs.faa 1e-5 10 &

#Circular contigs
python ~/scripts/VICA-master/find_circular.py -i virsorter_positive.fasta
grep '>' virsorter_positive.fasta_circular.fna | tr -d '>' > circular_contigs.ids

#Blast against databases
nohup blastn -query virsorter_positive.fasta -db /data/databases/blast/nt/nt -evalue 1e-10 -outfmt '6 qseqid sseqid pident length qlen slen evalue qstart qend sstart send title' -out virsorter_contigs_nt_outfmt6.txt -num_threads 10 &
nohup blastn -query virsorter_positive.fasta -db /data/databases/refseq_viral_89/viral.all.genomic.fna -evalue 1e-10 -outfmt '6 qseqid sseqid pident length qlen slen evalue qstart qend sstart send stitle' -out virsorter_contigs1_viral_refseq_outfmt6.txt -num_threads 5 &
nohup blastn -query virsorter_positive.fasta -db /data/databases/crass_like_phages/crass-like_db_249_crass001.fasta -evalue 1e-10 -outfmt '6 qseqid sseqid pident length qlen slen evalue qstart qend sstart send stitle' -out virsorter_contigs_crasslike_refseq_outfmt6.txt -num_threads 5 &
awk -F'\t' '$3 >= 50 {if (cov[$1"\t"$2"\t"$12] > 0) {cov[$1"\t"$2"\t"$12] = cov[$1"\t"$2"\t"$12] + $4/$5}else {cov[$1"\t"$2"\t"$12] = $4/$5}} END {for (i in cov) {if (cov[i] >= 0.9) print i"\t"cov[i]}}' virsorter_contigs_crasslike_refseq_outfmt6.txt | cut -f 1,3,4 > crasslike_annot.txt
awk -F'\t' '$3 >= 50 {if (cov[$1"\t"$2"\t"$12] > 0) {cov[$1"\t"$2"\t"$12] = cov[$1"\t"$2"\t"$12] + $4/$5}else {cov[$1"\t"$2"\t"$12] = $4/$5}} END {for (i in cov) {if (cov[i] >= 0.9) print i"\t"cov[i]}}' virsorter_contigs1_viral_refseq_outfmt6.txt | cut -f 1,3,4 > refseq_annot.txt

#Search for ribosomal proteins
nohup blastp -query translations_virsorter_contigs.faa -db ~/ribosomal_proteins_cog2014/ribosomal_proteins_cog_filtered.fa -evalue 1e-10 -outfmt '6 qseqid sseqid pident length qlen slen evalue qstart qend sstart send stitle' -out ribosomal_proteins_cog_filtered_outfmt6.txt -num_threads 10 &
cut -f 1 ribosomal_proteins_cog_filtered_outfmt6.txt | sort | uniq | grep -o '^.*_' | sed -e 's/.$//' | sort | uniq -c | sort -k 1,1 -h > ribosomal_prot_counts.txt

#GC cotent
## Not used in paper - not sure what to do 
infoseq virsorter_positive.fasta | grep -o 'N   .*$' | grep -o ' [0-9]\{2\}\.[0-9]\{2\}' | tr -d ' ' > gc_content.txt
paste virsorter_positive.ids gc_content.txt > virsorter_positive_gc_content.txt

#CRISPR matches with host bacteria
makeblastdb -in virsorter_positive.fasta -dbtype nucl
nohup blastn -query ../../refseq_bacteria/bacteria_refseq89_pilercr.fasta -db virsorter_positive.fasta -task "blastn-short" -evalue 1E-5 -outfmt '6 qseqid sseqid bitscore pident length qlen evalue sstart send' -out refseq89_pilercr_selected_contigs_outfmt6.txt -num_threads 10 &
#for i in $(cat refseq89_pilercr_selected_contigs_outfmt6.txt | cut -f 1 | sed -e 's/^\(.*\)_.*$/\1/'); do grep $i ../../refseq_bacteria/refseq_bacteria_89_headers.txt | tr -d '>' >> selected_contigs_CRISPR_refseq_taxa.txt; done
#paste refseq89_pilercr_selected_contigs_outfmt6.txt selected_contigs_CRISPR_refseq_taxa.txt > refseq89_pilercr_blasthits_selected_contigs_taxa.txt

nohup blastn -query ../../hmp_bacteria/hmp_bacteria_pilercr.fasta -db virsorter_positive.fasta -task "blastn-short" -evalue 1E-05 -outfmt '6 qseqid sseqid bitscore pident length qlen evalue sstart send' -out hmp_pilercr_selected_contigs_outfmt6.txt -num_threads 10 &
for i in $(cat hmp_pilercr_selected_contigs_outfmt6.txt | cut -f 1 | sed -e 's/^\(.*\)_.*$/\1/'); do awk -v cont_name=$i '$1 == cont_name' ../../hmp_bacteria/hmp_bacteria_headers2.txt | head -n 1 >> selected_contigs_CRISPR_hmp_taxa.txt; done
paste hmp_pilercr_selected_contigs_outfmt6.txt selected_contigs_CRISPR_hmp_taxa.txt > hmp_pilercr_blasthits_selected_contigs_taxa.txt

#Temperate phages
for i in $(cat Integrase_SSRecombinase_voglist.txt); do awk -v i="$i" '$1 == i {print $3}' all_pvogs_hmm_tblout.txt >> integrases.ids; done
sed -e 's/_[0-9]\{1,10\}$//' integrases.ids | sort | uniq > integrase_contigs.ids

#Filter by breadth of coverage
for i in $(ls *.bam.sorted.bam); do sh ~/scripts/breadth_cov_v1.sh $i; done
for i in $(ls *.bam.sorted.bam.covperc); do sh ~/scripts/cov_collate_v1.sh $i; done
sh ~/scripts/cov_collate_1file_v1.sh
rm *.covperc *.covperc.full *.covtab
