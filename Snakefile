configfile: "config/config.yaml"
threads_max=int(config["threads"])

rule all:
    input:
        png=expand("metaPlotR/{sample_name}.TEST.png", sample_name=config["sample_name"])

rule ip_fastqc_preAdapters:
    input:
        read1=expand("{r1}.fastq.gz", r1=config["reads"]["ip"]["ip_read1"]),
        read2=expand("{r2}.fastq.gz", r2=config["reads"]["ip"]["ip_read2"])
    output:
        directory("IP/fastqc/preAdapters/")
    message: "Analyzing read quality with FastQC..."
    params:
        adapters=expand("{adapters}", adapters=config["adapters"])
    threads: threads_max
    shell:
        "fastqc -t {threads} -a {params.adapters} -o {output} {input}"

rule ip_umitools_extract:
    #Read 1 & Read 2 are switched to work better with UMI-tools
    input:
        read1=expand("{r1}.fastq.gz", r1=config["reads"]["ip"]["ip_read1"]),
        read2=expand("{r2}.fastq.gz", r2=config["reads"]["ip"]["ip_read2"]),
        fastqc=rules.ip_fastqc_preAdapters.output
    output:
        read1=expand("IP/umitools/{r1}.umiExtracted.fastq.gz", r1=config["reads"]["ip"]["ip_read1"]),
        read2=expand("IP/umitools/{r2}.umiExtracted.fastq.gz", r2=config["reads"]["ip"]["ip_read2"])
    message: "Extracting UMIs with UMI-tools..."
    log:
        "IP/logs/umitools_extract.log"
    shell:
        "umi_tools extract -I {input.read2} --bc-pattern=NNNNNNNNNN --read2-in={input.read1} --stdout={output.read2} --read2-out={output.read1} --log={log}"

rule ip_cutadapt_round1:
    input:
        read1=expand("IP/umitools/{r1}.umiExtracted.fastq.gz", r1=config["reads"]["ip"]["ip_read1"]),
        read2=expand("IP/umitools/{r2}.umiExtracted.fastq.gz", r2=config["reads"]["ip"]["ip_read2"])
    output:
        read1=expand("IP/cutadapt/round1/{r1}.umiExtracted.adapterTrim.fastq.gz", r1=config["reads"]["ip"]["ip_read1"]),
        read2=expand("IP/cutadapt/round1/{r2}.umiExtracted.adapterTrim.fastq.gz", r2=config["reads"]["ip"]["ip_read2"])
    threads: threads_max
    message: "Removing adapters with cutadapt..."
    log:
        "IP/logs/cutadapt_round1.metrics"
    shell:
        "cutadapt --match-read-wildcards --quality-cutoff 6 -m 18 -j {threads} -a NNNNNNNNNNAGATCGGAAGAGCACACGTCTGAACTCCAGTCAC -g CTTCCGATCTNNNNNCCTATAT -g CTTCCGATCTNNNNNTGCTATT -A ATATAGGNNNNNAGA -A TATAGGNNNNNAGAT -A ATAGGNNNNNAGATC -A TAGGNNNNNAGATCG -A AGGNNNNNAGATCGG -A GGNNNNNAGATCGGA -A GNNNNNAGATCGGAA -A NNNNNAGATCGGAAG -A NNNNAGATCGGAAGA -A NNNAGATCGGAAGAG -A NNAGATCGGAAGAGC -A NAGATCGGAAGAGCG -A AGATCGGAAGAGCGT -A GATCGGAAGAGCGTC -A ATCGGAAGAGCGTCG -A TCGGAAGAGCGTCGT -A CGGAAGAGCGTCGTG -A GGAAGAGCGTCGTGT -A GAAGAGCGTCGTGTA -A AAGAGCGTCGTGTA -A AATAGCANNNNNAGA -A ATAGCANNNNNAGAT -A TAGCANNNNNAGATC -A AGCANNNNNAGATCG -A GCANNNNNAGATCGG -A CANNNNNAGATCGGA -A ANNNNNAGATCGGAA -o {output.read1} -p {output.read2} {input} > {log}"

rule ip_cutadapt_round2:
    input:
        read1=expand("IP/cutadapt/round1/{r1}.umiExtracted.adapterTrim.fastq.gz", r1=config["reads"]["ip"]["ip_read1"]),
        read2=expand("IP/cutadapt/round1/{r2}.umiExtracted.adapterTrim.fastq.gz", r2=config["reads"]["ip"]["ip_read2"])
    output:
        read1=expand("IP/cutadapt/round2/{r1}.umiExtracted.adapterTrim.round2.fastq.gz", r1=config["reads"]["ip"]["ip_read1"]),
        read2=expand("IP/cutadapt/round2/{r2}.umiExtracted.adapterTrim.round2.fastq.gz", r2=config["reads"]["ip"]["ip_read2"])
    threads: threads_max
    log:
        "IP/logs/cutadapt_round2.metrics"
    shell:
        "cutadapt --match-read-wildcards -O 5 --quality-cutoff 6 -m 18 -j 3 -g CTTCCGATCTNNNNNCCTATAT -g CTTCCGATCTNNNNNTGCTATT -A ATATAGGNNNNNAGA -A TATAGGNNNNNAGAT -A ATAGGNNNNNAGATC -A TAGGNNNNNAGATCG -A AGGNNNNNAGATCGG -A GGNNNNNAGATCGGA -A GNNNNNAGATCGGAA -A NNNNNAGATCGGAAG -A NNNNAGATCGGAAGA -A NNNAGATCGGAAGAG -A NNAGATCGGAAGAGC -A NAGATCGGAAGAGCG -A AGATCGGAAGAGCGT -A GATCGGAAGAGCGTC -A ATCGGAAGAGCGTCG -A TCGGAAGAGCGTCGT -A CGGAAGAGCGTCGTG -A GGAAGAGCGTCGTGT -A GAAGAGCGTCGTGTA -A AAGAGCGTCGTGTA -A AATAGCANNNNNAGA -A ATAGCANNNNNAGAT -A TAGCANNNNNAGATC -A AGCANNNNNAGATCG -A GCANNNNNAGATCGG -A CANNNNNAGATCGGA -A ANNNNNAGATCGGAA -o {output.read1} -p {output.read2} {input} > {log}"

rule ip_fastqc_postAdapters:
    input:
        read1=expand("IP/cutadapt/round2/{r1}.umiExtracted.adapterTrim.round2.fastq.gz", r1=config["reads"]["ip"]["ip_read1"]),
        read2=expand("IP/cutadapt/round2/{r2}.umiExtracted.adapterTrim.round2.fastq.gz", r2=config["reads"]["ip"]["ip_read2"])
    output:
        directory("IP/fastqc/postAdapters/")
    message: "Analyzing read quality again to confirm adapters were removed..."
    params:
        adapters=expand("{adapters}", adapters=config["adapters"])
    threads: threads_max
    shell:
        "fastqc -t {threads} -a {params.adapters} -o {output} {input}"

rule ip_STAR_repbase:
    input:
        read1=expand("IP/cutadapt/round2/{r1}.umiExtracted.adapterTrim.round2.fastq.gz", r1=config["reads"]["ip"]["ip_read1"]),
        read2=expand("IP/cutadapt/round2/{r2}.umiExtracted.adapterTrim.round2.fastq.gz", r2=config["reads"]["ip"]["ip_read2"]),
        fastqc=rules.ip_fastqc_postAdapters.output
    output:
        bam=expand("IP/STAR/repbase/{sample_name}_IP.umiExtracted.adapterTrim.round2.repbase.bam", sample_name=config["sample_name"]),
        mate1=expand("IP/STAR/repbase/{sample_name}_IP.umiExtracted.adapterTrim.round2.repbase.Unmapped.out.sorted.mate1", sample_name=config["sample_name"]),
        mate2=expand("IP/STAR/repbase/{sample_name}_IP.umiExtracted.adapterTrim.round2.repbase.Unmapped.out.sorted.mate2", sample_name=config["sample_name"])
    message: "Mapping reads to RepBase with STAR to remove repeats..."
    params:
        genome=expand("{genome}", genome=config["STAR"]["repbase"]),
        prefix=expand("IP/STAR/repbase/{sample_name}_IP.umiExtracted.adapterTrim.round2.repbase.", sample_name=config["sample_name"])
    threads: threads_max
    shell:
        "STAR --runThreadN {threads} --runMode alignReads --genomeDir {params.genome} --readFilesIn {input.read1} {input.read2} --outSAMunmapped Within --outFilterMultimapNmax 30 --outFilterMultimapScoreRange 1 --outFileNamePrefix {params.prefix} --outSAMattributes All --readFilesCommand zcat --outStd BAM_Unsorted --outSAMtype BAM Unsorted --outFilterType BySJout --outReadsUnmapped Fastx --outFilterScoreMin 10 --outSAMattrRGline ID:foo --alignEndsType EndToEnd > {output.bam} && "
        "fastq-sort --id {params.prefix}Unmapped.out.mate1 > {output.mate1} && "
        "fastq-sort --id {params.prefix}Unmapped.out.mate2 > {output.mate2}"

rule ip_STAR_genome:
    input:
        read1=expand("IP/STAR/repbase/{sample_name}_IP.umiExtracted.adapterTrim.round2.repbase.Unmapped.out.sorted.mate1", sample_name=config["sample_name"]),
        read2=expand("IP/STAR/repbase/{sample_name}_IP.umiExtracted.adapterTrim.round2.repbase.Unmapped.out.sorted.mate2", sample_name=config["sample_name"])
    output:
        bam=expand("IP/STAR/genome/{sample_name}_IP.umiExtracted.adapterTrim.round2.rmRep.bam", sample_name=config["sample_name"]),
        sorted_bam=expand("IP/STAR/genome/{sample_name}_IP.umiExtracted.adapterTrim.round2.rmRep.sorted.bam", sample_name=config["sample_name"])
    message: "Mapping unique reads to genome with STAR..."
    params:
        genome=expand("{genome}", genome=config["STAR"]["genome"]),
        prefix=expand("IP/STAR/genome/{sample_name}_IP.umiExtracted.adapterTrim.round2.rmRep.", sample_name=config["sample_name"])
    threads: threads_max
    shell:
        "STAR --runThreadN {threads} --runMode alignReads --genomeDir {params.genome} --readFilesIn {input.read1} {input.read2} --outSAMunmapped Within --outFilterMultimapNmax 1 --outFileNamePrefix {params.prefix} --outSAMattributes All --outStd BAM_Unsorted --outSAMtype BAM Unsorted --outFilterType BySJout --outReadsUnmapped Fastx --outFilterScoreMin 10 --outSAMattrRGline ID:foo --alignEndsType EndToEnd --outFilterScoreMinOverLread 0 --outFilterMatchNminOverLread 0 > {output.bam} && "
        "samtools sort {output.bam} -o {output.sorted_bam} && "
        "samtools index {output.sorted_bam}"

rule ip_umitools_dedup:
    input:
        bam=expand("IP/STAR/genome/{sample_name}_IP.umiExtracted.adapterTrim.round2.rmRep.sorted.bam", sample_name=config["sample_name"])
    output:
        bam=expand("IP/umitools/dedup/{sample_name}_IP.umiExtracted.adapterTrim.round2.rmRep.sorted.rmDup.bam", sample_name=config["sample_name"]),
        sorted_bam=expand("IP/umitools/dedup/{sample_name}_IP.umiExtracted.adapterTrim.round2.rmRep.sorted.rmDup.sorted.bam", sample_name=config["sample_name"]),
        r2=expand("IP/umitools/dedup/{sample_name}_IP.umiExtracted.adapterTrim.round2.rmRep.sorted.rmDup.sorted.r2.bam", sample_name=config["sample_name"])
    message: "Removing duplicates with UMI-tools..."
    params:
        stats=expand("IP/umitools/dedup/{sample_name}_IP.umitools_dedup_stats", sample_name=config["sample_name"]),
    log:
        "IP/logs/umitools_dedup.log"
    shell:
        "umi_tools dedup -I {input.bam} --paired -S {output.bam} --output-stats={params.stats} --log={log} && "
        "samtools sort {output.bam} -o {output.sorted_bam} && "
        "samtools index {output.sorted_bam} && "
        "samtools view -hb -f 128 {output.sorted_bam} > {output.r2} && "
        "samtools index {output.r2}"

rule ip_samtools_mpileup:
    input:
        bam=expand("IP/umitools/dedup/{sample_name}_IP.umiExtracted.adapterTrim.round2.rmRep.sorted.rmDup.sorted.r2.bam", sample_name=config["sample_name"])
    output:
        mpileup=expand("IP/mpileup/{sample_name}_IP.umiExtracted.adapterTrim.round2.rmRep.sorted.rmDup.sorted.r2.mpileup", sample_name=config["sample_name"])
    params:
        fasta=expand("{fasta}", fasta=config["genome"]["fasta"])
    message: "Identifying C-to-T mutations with mpileup..."
    shell:
        "samtools mpileup -B -f {params.fasta} {input.bam} > {output.mpileup}"

rule ip_meCLIP:
    input:
        mpileup=expand("IP/mpileup/{sample_name}_IP.umiExtracted.adapterTrim.round2.rmRep.sorted.rmDup.sorted.r2.mpileup", sample_name=config["sample_name"]),
        rule=rules.ip_samtools_mpileup.output
    output:
        motifFrequency_positive=expand("IP/mpileup/{sample_name}_IP_mpileupParser_positive_motifFrequency.xls", sample_name=config["sample_name"]),
        motifFrequency_negative=expand("IP/mpileup/{sample_name}_IP_mpileupParser_negative_motifFrequency.xls", sample_name=config["sample_name"])
    params:
        twoBit=expand("{twoBit}", twoBit=config["genome"]["twoBit"]),
        prefix=expand("{sample_name}_IP", sample_name=config["sample_name"])
    message: "Parsing results to identify m6A sites..."
    shell:
        "java -jar scripts/jars/mpileupParser.jar {input.mpileup} {params.prefix} 0.025 0.5 2 0 && "
        "twoBitToFa {params.twoBit} IP/mpileup/motifList_positive.fa -seqList=IP/mpileup/{params.prefix}_motifList_positive.txt && "
        "twoBitToFa {params.twoBit} IP/mpileup/motifList_negative.fa -seqList=IP/mpileup/{params.prefix}_motifList_negative.txt && "
        "java -jar scripts/jars/meCLIP_motifFrequency.jar IP/mpileup/motifList_positive.fa IP/mpileup/{params.prefix}_mpileupParser_positive.xls [AG]AC && "
        "java -jar scripts/jars/meCLIP_motifFrequency.jar IP/mpileup/motifList_negative.fa IP/mpileup/{params.prefix}_mpileupParser_negative.xls GT[TC]"

rule ip_formatOutput:
    input:
        motifFrequency_positive=expand("IP/mpileup/{sample_name}_IP_mpileupParser_positive_motifFrequency.xls", sample_name=config["sample_name"]),
        motifFrequency_negative=expand("IP/mpileup/{sample_name}_IP_mpileupParser_negative_motifFrequency.xls", sample_name=config["sample_name"])
    output:
        xls=expand("IP/{sample_name}_IP.mpileupParser_motifFrequency.xls", sample_name=config["sample_name"])
    params:
        sample_name=expand("{sample_name}_IP", sample_name=config["sample_name"])
    shell:
        """
        cat <(echo -e "Chr \tM6A \tRef \tFreq \tMutationCount \tReadCount \tMotifStart \tMotifEnd \tMotif") {input.motifFrequency_positive} {input.motifFrequency_negative} > {output.xls} && \
        awk '{{if ($9!="No") print $0}}' {output.xls} > {output.xls}.temp && mv {output.xls}.temp {output.xls}
        """

rule input_fastqc_preAdapters:
    input:
        read1=expand("{r1}.fastq.gz", r1=config["reads"]["input"]["input_read1"]),
        read2=expand("{r2}.fastq.gz", r2=config["reads"]["input"]["input_read2"]),
        xls=rules.ip_formatOutput.output
    output:
        directory("INPUT/fastqc/preAdapters/")
    message: "Starting Input sample analysis..."
    params:
        adapters=expand("{adapters}", adapters=config["adapters"])
    threads: threads_max
    shell:
        "fastqc -t {threads} -a {params.adapters} -o {output} {input.read1} {input.read2} "

rule input_umitools_extract:
    #Read 1 & Read 2 are switched to work better with UMI-tools
    input:
        read1=expand("{r1}.fastq.gz", r1=config["reads"]["input"]["input_read1"]),
        read2=expand("{r2}.fastq.gz", r2=config["reads"]["input"]["input_read2"]),
        fastqc=rules.input_fastqc_preAdapters.output
    output:
        read1=expand("INPUT/umitools/{r1}.umiExtracted.fastq.gz", r1=config["reads"]["input"]["input_read1"]),
        read2=expand("INPUT/umitools/{r2}.umiExtracted.fastq.gz", r2=config["reads"]["input"]["input_read2"])
    message: "Extracting UMIs with UMI-tools..."
    log:
        "INPUT/logs/umitools_extract.log"
    shell:
        "umi_tools extract -I {input.read2} --bc-pattern=NNNNNNNNNN --read2-in={input.read1} --stdout={output.read2} --read2-out={output.read1} --log={log}"

rule input_cutadapt_round1:
    input:
        read1=expand("INPUT/umitools/{r1}.umiExtracted.fastq.gz", r1=config["reads"]["input"]["input_read1"]),
        read2=expand("INPUT/umitools/{r2}.umiExtracted.fastq.gz", r2=config["reads"]["input"]["input_read2"])
    output:
        read1=expand("INPUT/cutadapt/round1/{r1}.umiExtracted.adapterTrim.fastq.gz", r1=config["reads"]["input"]["input_read1"]),
        read2=expand("INPUT/cutadapt/round1/{r2}.umiExtracted.adapterTrim.fastq.gz", r2=config["reads"]["input"]["input_read2"])
    threads: threads_max
    message: "Removing adapters with cutadapt..."
    log:
        "INPUT/logs/cutadapt_round1.metrics"
    shell:
        "cutadapt --match-read-wildcards --quality-cutoff 6 -m 18 -j {threads} -a NNNNNNNNNNAGATCGGAAGAGCACACGTCTGAACTCCAGTCAC -g CTTCCGATCTNNNNNCCTATAT -g CTTCCGATCTNNNNNTGCTATT -A ATATAGGNNNNNAGA -A TATAGGNNNNNAGAT -A ATAGGNNNNNAGATC -A TAGGNNNNNAGATCG -A AGGNNNNNAGATCGG -A GGNNNNNAGATCGGA -A GNNNNNAGATCGGAA -A NNNNNAGATCGGAAG -A NNNNAGATCGGAAGA -A NNNAGATCGGAAGAG -A NNAGATCGGAAGAGC -A NAGATCGGAAGAGCG -A AGATCGGAAGAGCGT -A GATCGGAAGAGCGTC -A ATCGGAAGAGCGTCG -A TCGGAAGAGCGTCGT -A CGGAAGAGCGTCGTG -A GGAAGAGCGTCGTGT -A GAAGAGCGTCGTGTA -A AAGAGCGTCGTGTA -A AATAGCANNNNNAGA -A ATAGCANNNNNAGAT -A TAGCANNNNNAGATC -A AGCANNNNNAGATCG -A GCANNNNNAGATCGG -A CANNNNNAGATCGGA -A ANNNNNAGATCGGAA -o {output.read1} -p {output.read2} {input} > {log}"

rule input_cutadapt_round2:
    input:
        read1=expand("INPUT/cutadapt/round1/{r1}.umiExtracted.adapterTrim.fastq.gz", r1=config["reads"]["input"]["input_read1"]),
        read2=expand("INPUT/cutadapt/round1/{r2}.umiExtracted.adapterTrim.fastq.gz", r2=config["reads"]["input"]["input_read2"])
    output:
        read1=expand("INPUT/cutadapt/round2/{r1}.umiExtracted.adapterTrim.round2.fastq.gz", r1=config["reads"]["input"]["input_read1"]),
        read2=expand("INPUT/cutadapt/round2/{r2}.umiExtracted.adapterTrim.round2.fastq.gz", r2=config["reads"]["input"]["input_read2"])
    threads: threads_max
    log:
        "INPUT/logs/cutadapt_round2.metrics"
    shell:
        "cutadapt --match-read-wildcards -O 5 --quality-cutoff 6 -m 18 -j 3 -g CTTCCGATCTNNNNNCCTATAT -g CTTCCGATCTNNNNNTGCTATT -A ATATAGGNNNNNAGA -A TATAGGNNNNNAGAT -A ATAGGNNNNNAGATC -A TAGGNNNNNAGATCG -A AGGNNNNNAGATCGG -A GGNNNNNAGATCGGA -A GNNNNNAGATCGGAA -A NNNNNAGATCGGAAG -A NNNNAGATCGGAAGA -A NNNAGATCGGAAGAG -A NNAGATCGGAAGAGC -A NAGATCGGAAGAGCG -A AGATCGGAAGAGCGT -A GATCGGAAGAGCGTC -A ATCGGAAGAGCGTCG -A TCGGAAGAGCGTCGT -A CGGAAGAGCGTCGTG -A GGAAGAGCGTCGTGT -A GAAGAGCGTCGTGTA -A AAGAGCGTCGTGTA -A AATAGCANNNNNAGA -A ATAGCANNNNNAGAT -A TAGCANNNNNAGATC -A AGCANNNNNAGATCG -A GCANNNNNAGATCGG -A CANNNNNAGATCGGA -A ANNNNNAGATCGGAA -o {output.read1} -p {output.read2} {input} > {log}"

rule input_fastqc_postAdapters:
    input:
        read1=expand("INPUT/cutadapt/round2/{r1}.umiExtracted.adapterTrim.round2.fastq.gz", r1=config["reads"]["input"]["input_read1"]),
        read2=expand("INPUT/cutadapt/round2/{r2}.umiExtracted.adapterTrim.round2.fastq.gz", r2=config["reads"]["input"]["input_read2"])
    output:
        directory("INPUT/fastqc/postAdapters/")
    message: "Analyzing read quality again to confirm adapters were removed..."
    params:
        adapters=expand("{adapters}", adapters=config["adapters"])
    threads: threads_max
    shell:
        "fastqc -t {threads} -a {params.adapters} -o {output} {input}"

rule input_STAR_repbase:
    input:
        read1=expand("INPUT/cutadapt/round2/{r1}.umiExtracted.adapterTrim.round2.fastq.gz", r1=config["reads"]["input"]["input_read1"]),
        read2=expand("INPUT/cutadapt/round2/{r2}.umiExtracted.adapterTrim.round2.fastq.gz", r2=config["reads"]["input"]["input_read2"]),
        fastqc=rules.input_fastqc_postAdapters.output
    output:
        bam=expand("INPUT/STAR/repbase/{sample_name}_INPUT.umiExtracted.adapterTrim.round2.repbase.bam", sample_name=config["sample_name"]),
        mate1=expand("INPUT/STAR/repbase/{sample_name}_INPUT.umiExtracted.adapterTrim.round2.repbase.Unmapped.out.sorted.mate1", sample_name=config["sample_name"]),
        mate2=expand("INPUT/STAR/repbase/{sample_name}_INPUT.umiExtracted.adapterTrim.round2.repbase.Unmapped.out.sorted.mate2", sample_name=config["sample_name"])
    message: "Mapping reads to RepBase with STAR to remove repeats..."
    params:
        genome=expand("{genome}", genome=config["STAR"]["repbase"]),
        prefix=expand("INPUT/STAR/repbase/{sample_name}_INPUT.umiExtracted.adapterTrim.round2.repbase.", sample_name=config["sample_name"])
    threads: threads_max
    shell:
        "STAR --runThreadN {threads} --runMode alignReads --genomeDir {params.genome} --readFilesIn {input.read1} {input.read2} --outSAMunmapped Within --outFilterMultimapNmax 30 --outFilterMultimapScoreRange 1 --outFileNamePrefix {params.prefix} --outSAMattributes All --readFilesCommand zcat --outStd BAM_Unsorted --outSAMtype BAM Unsorted --outFilterType BySJout --outReadsUnmapped Fastx --outFilterScoreMin 10 --outSAMattrRGline ID:foo --alignEndsType EndToEnd > {output.bam} && "
        "fastq-sort --id {params.prefix}Unmapped.out.mate1 > {output.mate1} && "
        "fastq-sort --id {params.prefix}Unmapped.out.mate2 > {output.mate2}"

rule input_STAR_genome:
    input:
        read1=expand("INPUT/STAR/repbase/{sample_name}_INPUT.umiExtracted.adapterTrim.round2.repbase.Unmapped.out.sorted.mate1", sample_name=config["sample_name"]),
        read2=expand("INPUT/STAR/repbase/{sample_name}_INPUT.umiExtracted.adapterTrim.round2.repbase.Unmapped.out.sorted.mate2", sample_name=config["sample_name"])
    output:
        bam=expand("INPUT/STAR/genome/{sample_name}_INPUT.umiExtracted.adapterTrim.round2.rmRep.bam", sample_name=config["sample_name"]),
        sorted_bam=expand("INPUT/STAR/genome/{sample_name}_INPUT.umiExtracted.adapterTrim.round2.rmRep.sorted.bam", sample_name=config["sample_name"])
    message: "Mapping unique reads to genome with STAR..."
    params:
        genome=expand("{genome}", genome=config["STAR"]["genome"]),
        prefix=expand("INPUT/STAR/genome/{sample_name}_INPUT.umiExtracted.adapterTrim.round2.rmRep.", sample_name=config["sample_name"])
    threads: threads_max
    shell:
        "STAR --runThreadN {threads} --runMode alignReads --genomeDir {params.genome} --readFilesIn {input.read1} {input.read2} --outSAMunmapped Within --outFilterMultimapNmax 1 --outFileNamePrefix {params.prefix} --outSAMattributes All --outStd BAM_Unsorted --outSAMtype BAM Unsorted --outFilterType BySJout --outReadsUnmapped Fastx --outFilterScoreMin 10 --outSAMattrRGline ID:foo --alignEndsType EndToEnd --outFilterScoreMinOverLread 0 --outFilterMatchNminOverLread 0 > {output.bam} && "
        "samtools sort {output.bam} -o {output.sorted_bam} && "
        "samtools index {output.sorted_bam}"

rule input_umitools_dedup:
    input:
        bam=expand("INPUT/STAR/genome/{sample_name}_INPUT.umiExtracted.adapterTrim.round2.rmRep.sorted.bam", sample_name=config["sample_name"])
    output:
        bam=expand("INPUT/umitools/dedup/{sample_name}_INPUT.umiExtracted.adapterTrim.round2.rmRep.sorted.rmDup.bam", sample_name=config["sample_name"]),
        sorted_bam=expand("INPUT/umitools/dedup/{sample_name}_INPUT.umiExtracted.adapterTrim.round2.rmRep.sorted.rmDup.sorted.bam", sample_name=config["sample_name"]),
        r2=expand("INPUT/umitools/dedup/{sample_name}_INPUT.umiExtracted.adapterTrim.round2.rmRep.sorted.rmDup.sorted.r2.bam", sample_name=config["sample_name"])
    message: "Removing duplicates with UMI-tools..."
    params:
        stats=expand("INPUT/umitools/dedup/{sample_name}_INPUT.umitools_dedup_stats", sample_name=config["sample_name"])
    log:
        "INPUT/logs/umitools_dedup.log"
    shell:
        "umi_tools dedup -I {input.bam} --paired -S {output.bam} --output-stats={params.stats} --log={log} && "
        "samtools sort {output.bam} -o {output.sorted_bam} && "
        "samtools index {output.sorted_bam} && "
        "samtools view -hb -f 128 {output.sorted_bam} > {output.r2} && "
        "samtools index {output.r2}"

rule input_samtools_mpileup:
    input:
        bam=expand("INPUT/umitools/dedup/{sample_name}_INPUT.umiExtracted.adapterTrim.round2.rmRep.sorted.rmDup.sorted.r2.bam", sample_name=config["sample_name"])
    output:
        mpileup=expand("INPUT/mpileup/{sample_name}_INPUT.umiExtracted.adapterTrim.round2.rmRep.sorted.rmDup.sorted.r2.mpileup", sample_name=config["sample_name"])
    params:
        fasta=expand("{fasta}", fasta=config["genome"]["fasta"])
    message: "Identifying C-to-T mutations with mpileup..."
    shell:
        "samtools mpileup -B -f {params.fasta} {input.bam} > {output.mpileup}"

rule input_meCLIP:
    input:
        mpileup=expand("INPUT/mpileup/{sample_name}_INPUT.umiExtracted.adapterTrim.round2.rmRep.sorted.rmDup.sorted.r2.mpileup", sample_name=config["sample_name"]),
        rule=rules.input_samtools_mpileup.output
    output:
        motifFrequency_positive=expand("INPUT/mpileup/{sample_name}_INPUT_mpileupParser_positive_motifFrequency.xls", sample_name=config["sample_name"]),
        motifFrequency_negative=expand("INPUT/mpileup/{sample_name}_INPUT_mpileupParser_negative_motifFrequency.xls", sample_name=config["sample_name"])
    params:
        twoBit=expand("{twoBit}", twoBit=config["genome"]["twoBit"]),
        prefix=expand("{sample_name}_INPUT", sample_name=config["sample_name"])
    message: "Parsing results to identify m6A sites..."
    shell:
        "java -jar scripts/jars/mpileupParser.jar {input.mpileup} {params.prefix} 0.025 0.5 2 0 && "
        "twoBitToFa {params.twoBit} INPUT/mpileup/motifList_positive.fa -seqList=INPUT/mpileup/{params.prefix}_motifList_positive.txt && "
        "twoBitToFa {params.twoBit} INPUT/mpileup/motifList_negative.fa -seqList=INPUT/mpileup/{params.prefix}_motifList_negative.txt && "
        "java -jar scripts/jars/meCLIP_motifFrequency.jar INPUT/mpileup/motifList_positive.fa INPUT/mpileup/{params.prefix}_mpileupParser_positive.xls [AG]AC && "
        "java -jar scripts/jars/meCLIP_motifFrequency.jar INPUT/mpileup/motifList_negative.fa INPUT/mpileup/{params.prefix}_mpileupParser_negative.xls GT[TC]"

rule input_formatOutput:
    input:
        motifFrequency_positive=expand("INPUT/mpileup/{sample_name}_INPUT_mpileupParser_positive_motifFrequency.xls", sample_name=config["sample_name"]),
        motifFrequency_negative=expand("INPUT/mpileup/{sample_name}_INPUT_mpileupParser_negative_motifFrequency.xls", sample_name=config["sample_name"])
    output:
        xls=expand("INPUT/{sample_name}_INPUT.mpileupParser_motifFrequency.xls", sample_name=config["sample_name"])
    params:
        sample_name=expand("{sample_name}_INPUT", sample_name=config["sample_name"])
    shell:
        """
        cat <(echo -e "Chr \tM6A \tRef \tFreq \tMutationCount \tReadCount \tMotifStart \tMotifEnd \tMotif") {input.motifFrequency_positive} {input.motifFrequency_negative} > {output.xls} && \
        awk '{{if ($9!="No") print $0}}' {output.xls} > {output.xls}.temp && mv {output.xls}.temp {output.xls}
        """

rule meCLIP_inputParser:
    input:
        ip_sample=expand("IP/{sample_name}_IP.mpileupParser_motifFrequency.xls", sample_name=config["sample_name"]),
        input_sample=expand("INPUT/{sample_name}_INPUT.mpileupParser_motifFrequency.xls", sample_name=config["sample_name"])
    output:
        xls=expand("{sample_name}.m6aList.xls", sample_name=config["sample_name"])
    message: "Comparing IP m6A calls to input and filtering out any overlaps..."
    shell:
        "java -jar scripts/jars/meCLIP_inputParser.jar {input.ip_sample} {input.input_sample} {output.xls}"

rule meCLIP_bedGenerator:
    input:
        xls=expand("{sample_name}.m6aList.xls", sample_name=config["sample_name"])
    output:
        bed=expand("{sample_name}.m6aList.bed", sample_name=config["sample_name"])
    params:
        sample_name=expand("{sample_name}", sample_name=config["sample_name"])
    message: "Generating BED files of m6A calls (sorted by confidence)..."
    shell:
        "java -jar scripts/jars/meCLIP_bedGenerator.jar {input.xls} {params.sample_name}.m6aList"

rule bedtools:
    input:
        bed=expand("{sample_name}.m6aList.bed", sample_name=config["sample_name"])
    output:
        bed=expand("{sample_name}.m6aList.sorted.annotated.bed", sample_name=config["sample_name"])
    params:
        sample_name=expand("{sample_name}", sample_name=config["sample_name"])
    shell:
        "sort -k1,1 -k2,2n {input.bed} > {params.sample_name}.m6aList.sorted.bed && "
        "bedtools intersect -a {params.sample_name}.m6aList.sorted.bed -b bed/hg19_annot.sorted.bed -wb -s -sorted > {output.bed}"

rule meCLIP_m6aAnnotator:
    input:
        bed=expand("{sample_name}.m6aList.sorted.annotated.bed", sample_name=config["sample_name"])
    output:
        xls=expand("{sample_name}.m6aList.FINAL.xls", sample_name=config["sample_name"])
    message: "Annotating list of m6As..."
    shell:
        "java -jar scripts/jars/meCLIP_m6aAnnotator.jar {input.bed} {output.xls}"

rule metaPlotR_perl:
    input:
        bed_m6a=expand("{sample_name}.m6aList.bed", sample_name=config["sample_name"]),
        bed_genome=expand("{hg19_annotation}", hg19_annotation=config["metaplotr"]["hg19_annotation"]),
        rule=rules.meCLIP_m6aAnnotator.output
    output:
        txt=expand("metaPlotR/{sample_name}.m6a.dist.measures.txt", sample_name=config["sample_name"])
    params:
        region_sizes=expand("{region_sizes}", region_sizes=config["metaplotr"]["region_sizes"])
    message: "Finishing annotation..."
    shell:
        "perl scripts/metaPlotR-master/annotate_bed_file.pl --bed {input.bed_m6a} --bed2 {input.bed_genome} > metaPlotR/annot_m6a.sorted.bed && "
        "perl scripts/metaPlotR-master/rel_and_abs_dist_calc.pl --bed metaPlotR/annot_m6a.sorted.bed --regions {params.region_sizes} > {output.txt}"

rule metaPlotR_R:
    input:
        txt=expand("metaPlotR/{sample_name}.m6a.dist.measures.txt", sample_name=config["sample_name"])
    output:
        png=expand("metaPlotR/{sample_name}.TEST.png", sample_name=config["sample_name"])
    params:
        sample_name=expand("{sample_name}", sample_name=config["sample_name"])
    message: "Generating metagene plot..."
    script:
        "scripts/metaPlotR-master/visualize_metagenes.R"
