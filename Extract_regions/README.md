# README

### Downloaded files:

* gencode.v48.annotation.gtf.gz: ([https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_48/gencode.v48.annotation.gtf.gz]())
* hg38.chrom.sizes ([http://hgdownload.soe.ucsc.edu/goldenpath/hg38/bigZips/hg38.chrom.sizes]())

### Extract introns:

1. Extract exons from annotaton:
   `zcat gencode.v48.annotation.gtf.gz | awk '$3=="exon"' > gencode.v48.annotation.exons.gtf`
2. Extract introns:
   `sort -k12,12 -k4,4n -k5,5n gencode.v48.annotation.exons.gtf | awk -v fldgn=10 -v fldtr=12 -f ../Utils/make_introns.awk > gencode.v48.annotation.introns.gtf`

### Extract intergenic regions:

1. Extract locus coord from annotation file:
   `zcat gencode.v48.annotation.gtf.gz | ../Utils/skipcomments - | ../Utils/extract_locus_coords.pl - > gencode.v48.annotation.loci.coords.bed6`
2. Reformat hg38.chrom.sizes to bed6:
   `cat hg38.chrom.sizes | awk '{print $1"\t"0"\t"$2"\t"$1"|0|"$2"\t"0"\t""-"}' > hg38.chrom.sizes.bed6`
   `cat hg38.chrom.sizes | awk '{print $1"\t"0"\t"$2"\t"$1"|0|"$2"\t"0"\t""+"}' >> hg38.chrom.sizes.bed6`
3. Subtract gene coordinates from chr sizes and convert to gtf:
   `bedtools subtract -s -a hg38.chrom.sizes.bed6 -b gencode.v48.annotation.loci.coords.bed6 | ../Utils/bed2gff.pl - | awk -F'\t' '{$3="intergenic"; OFS="\t"; print}' | sed 's/transcript_id/gene_id/g' > gencode.v48.annotation.intergenic.gtf`

### Combine exons + introns + intergenic:

`cat gencode.v48.annotation.exons.gtf gencode.v48.annotation.introns.gtf gencode.v48.annotation.intergenic.gtf | gzip > gencode.v48.annotation.combined.gtf.gz`

### Compress files to fit GitHub:

1. Gtf files:
   `gzip *gtf`
2. Other files:
   `gzip *bed6`
   `gzip hg38.chrom.sizes`
