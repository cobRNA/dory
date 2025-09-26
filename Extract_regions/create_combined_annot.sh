#!/usr/bin/env bash

# Handle errors
set -e          # exit on any non-0 exit status
set -o pipefail # exit on any non-0 exit status in pipe


### Download files:
echo '~~~ Download files ~~~'
# gencode.v49.annotation.gtf.gz:
wget https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_49/gencode.v49.annotation.gtf.gz
# hg38.chrom.sizes
wget http://hgdownload.soe.ucsc.edu/goldenpath/hg38/bigZips/hg38.chrom.sizes
echo '+++ DONE +++'

### Extract introns:
echo '~~~ Extract introns ~~~'
# Extract exons from annotaton:
zcat gencode.v49.annotation.gtf.gz | awk '$3=="exon"' > gencode.v49.annotation.exons.gtf
# Extract introns:
sort -k12,12 -k4,4n -k5,5n gencode.v49.annotation.exons.gtf | awk -v fldgn=10 -v fldtr=12 -f ../Utils/make_introns.awk > gencode.v49.annotation.introns.gtf
echo '+++ DONE +++'

### Extract intergenic regions:
echo '~~~ Extract intergenic regions ~~~'
# Extract locus coord from annotation file:
zcat gencode.v49.annotation.gtf.gz | ../Utils/skipcomments - | ../Utils/extract_locus_coords.pl - > gencode.v49.annotation.loci.coords.bed6
# Reformat hg38.chrom.sizes to bed6:
cat hg38.chrom.sizes | awk '{print $1"\t"0"\t"$2"\t"$1"|0|"$2"\t"0"\t""-"}' > hg38.chrom.sizes.bed6
cat hg38.chrom.sizes | awk '{print $1"\t"0"\t"$2"\t"$1"|0|"$2"\t"0"\t""+"}' >> hg38.chrom.sizes.bed6
# Subtract gene coordinates from chr sizes and convert to gtf:
bedtools subtract -s -a hg38.chrom.sizes.bed6 -b gencode.v49.annotation.loci.coords.bed6 | ../Utils/bed2gff.pl - | awk -F'\t' '{$3="intergenic"; OFS="\t"; print}' | sed 's/transcript_id/gene_id/g' > gencode.v49.annotation.intergenic.gtf
echo '+++ DONE +++'

### Combine exons + introns + intergenic + egfp:
echo '~~~ Combine exons + introns + intergenic ~~~'
gzip -d egfp_fixed.gtf.gz
cat gencode.v49.annotation.exons.gtf gencode.v49.annotation.introns.gtf gencode.v49.annotation.intergenic.gtf egfp_fixed.gtf | gzip -9 > gencode.v49.annotation.combined.gtf.gz
echo '+++ DONE +++'

### Compress files to fit GitHub:
echo '~~~ Compress files ~~~'
# Gtf files:
gzip -9 *gtf 
# Other files:
gzip -9 *bed6
gzip -9 hg38.chrom.sizes
echo '+++ DONE +++'

### Report progress
echo '>>>>>> COMPLETED!'
