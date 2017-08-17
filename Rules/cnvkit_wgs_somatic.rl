rule cnvkit_wgs_somatic:
    input: normal=lambda wildcards: config['project']['pairs'][wildcards.x][0]+".recal.bam",
           tumor=lambda wildcards: config['project']['pairs'][wildcards.x][1]+".recal.bam",
           normalgvcf=lambda wildcards: config['project']['pairs'][wildcards.x][0]+".g.vcf",
           tumorgvcf=lambda wildcards: config['project']['pairs'][wildcards.x][1]+".g.vcf",
    output: vcf=config['project']['workpath']+"/cnvkit_out/{x}_germpairs.vcf",
            filtvcf=config['project']['workpath']+"/cnvkit_out/{x}_filtGermpairs.vcf",
            calls=config['project']['workpath']+"/cnvkit_out/{x}_calls.cns",
            gainloss=config['project']['workpath']+"/cnvkit_out/{x}_gainloss.tsv",
            dir=config['project']['workpath']+"/cnvkit_out/{x}_cnvkit",
#            theta=config['project']['workpath']+"/cnvkit_out/{x}_thetaIN",
    params: gtf=config['references'][pfamily]['GTFFILE'],vcfdir=config['project']['workpath']+"/germline_vcfs",tumorsample=lambda wildcards: config['project']['pairs'][wildcards.x][1],normalsample=lambda wildcards: config['project']['pairs'][wildcards.x][0],access=config['references'][pfamily]['CNVKITACCESS'],antitargets=config['references'][pfamily]['CNVKITANTITARGETS'],genome=config['references'][pfamily]['CNVKITGENOME'],snpsites=config['references'][pfamily]['SNPSITES'],targets=config['references'][pfamily]['CNVKITWGSTARGETS'],rname="pl:cnvkit"
    threads: 4
    shell: "module load GATK/3.6; GATK -m 24G GenotypeGVCFs -R {params.genome} --annotation InbreedingCoeff --annotation FisherStrand --annotation QualByDepth --annotation ChromosomeCounts  --dbsnp {params.snpsites} -o {output.vcf} -nt {threads} --variant {input.normalgvcf} --variant {input.tumorgvcf}; module load vcftools; vcftools --vcf {output.vcf} --recode --recode-INFO-all --non-ref-ac-any 2 --remove-indels --max-missing 1 --minGQ 20 --out {params.normalsample}+{params.tumorsample}_filt; mv {params.normalsample}+{params.tumorsample}_filt.recode.vcf {output.filtvcf}; module load cnvkit/0.8.5; mkdir -p {output.dir}; cnvkit.py coverage {input.tumor} {params.targets} -q 20 -p {threads} -o {output.dir}/{params.tumorsample}.targetcoverage.cnn; cnvkit.py coverage {input.normal} {params.targets} -q 20 -p {threads} -o {output.dir}/{params.normalsample}.targetcoverage.cnn; cnvkit.py reference {output.dir}/{params.normalsample}.targetcoverage.cnn {params.antitargets} -f {params.genome} -o {output.dir}/{params.normalsample}.reference.cnn --no-edge; cnvkit.py fix {output.dir}/{params.tumorsample}.targetcoverage.cnn {params.antitargets} {output.dir}/{params.normalsample}.reference.cnn -o {output.dir}/{params.tumorsample}.cnr --no-edge; cnvkit.py segment {output.dir}/{params.tumorsample}.cnr -v {output.filtvcf} -i {params.tumorsample} -n {params.normalsample} -p {threads} -t 1e-6 -o {output.dir}/{params.tumorsample}.cns; cnvkit.py scatter {output.dir}/{params.tumorsample}.cnr -s {output.dir}/{params.tumorsample}.cns -v {output.filtvcf} -i {params.tumorsample} -n {params.normalsample} -o {output.dir}/{params.tumorsample}.pdf; cnvkit.py call -o {output.calls} -v {output.filtvcf} -i {params.tumorsample} -n {params.normalsample} {output.dir}/{params.tumorsample}.cns; cnvkit.py gainloss -s {output.dir}/{params.tumorsample}.cns -t 0.3 -o {output.gainloss} {output.dir}/{params.tumorsample}.cnr; cnvkit.py segmetrics -s {output.dir}/{params.tumorsample}.cns -o {output.dir}/{params.tumorsample}.segmetrics --mean --median --mode --stdev --sem --mad --mse --iqr --bivar --ci --pi -b 1000 {output.dir}/{params.tumorsample}.cnr"