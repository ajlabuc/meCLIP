configfile: "config/manual-reference-genome.yaml"
threads_max=int(config["resources"]["threads"])

rule all:
    input:
        "resources/referenceGenome.region_sizes.txt"

rule genome_download:
    output:
        "resources/referenceGenome.region_sizes.txt"
    params:
        fasta=expand("{fasta}", fasta=config["genome"]["fasta"]),
        gtf=expand("{gtf}", gtf=config["genome"]["gtf"]),
        ram=expand("{ram}", ram=config["resources"]["ram"])
    log:
        "results/logs/STAR_genomeGenerate.log"
    message: "Downloading, indexing, and annotating reference genome..."
    threads: threads_max
    shell:
        """
        mkdir -p resources; \
        wget -P resources {params.fasta}; \
        wget -P resources {params.gtf}; \
        gzip -dr resources; \
        ram="$(({params.ram}*1000000000))"; \
        echo "$(date +%b' '%d' '%H:%M:%S) Indexing genome (takes a while)..."; \
        STAR --runThreadN {threads_max} --limitGenomeGenerateRAM ${{ram}} --runMode genomeGenerate --genomeSAsparseD 2 --genomeFastaFiles resources/*.fa --sjdbGTFfile resources/*.gtf --genomeDir resources/index > {log} && \
        echo "$(date +%b' '%d' '%H:%M:%S) Annotating genome (takes a while)..." && \
        seqkit split resources/*.fa -i --by-id-prefix "" --id-regexp "([^\s]+)" -O resources/chroms --quiet && \
        awk -F'"' -v OFS='"' '{{for(i=2; i<=NF; i+=2) gsub(";", "-", $i)}} 1' resources/*.gtf | gtf2bed --attribute-key=gene_name - > resources/referenceGenome.geneNames.bed && \
        gtfToGenePred -genePredExt resources/*.gtf resources/referenceGenome.genePred && \
        perl workflow/scripts/metaPlotR/make_annot_bed.pl --genomeDir resources/chroms/ --genePred resources/referenceGenome.genePred > resources/referenceGenome.annotated.bed && \
        echo "$(date +%b' '%d' '%H:%M:%S) Sorting annotation..." && \
        sort -k1,1 -k2,2n resources/referenceGenome.annotated.bed > resources/referenceGenome.annotated.sorted.bed && \
        rm resources/referenceGenome.annotated.bed && \
        echo "$(date +%b' '%d' '%H:%M:%S) Calculating size of transcript regions (i.e. 5'UTR, CDS and 3'UTR)..." && \
        perl workflow/scripts/metaPlotR/size_of_cds_utrs.pl --annot resources/referenceGenome.annotated.sorted.bed > resources/referenceGenome.region_sizes.txt
        """