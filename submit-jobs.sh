#!/bin/bash -l

# Execute the script from the current directory
#$ -cwd

# Combine SGE error and output files.
#$ -j y

# Memory resource requirements
# 8/9, 22/23, 4/5
#$ -l excl=false,h_vmem=8g,virtual_free=10g 

# Cluster queue to use
#$ -q rascals.q@jane.pbtech,rascals.q@wally.pbtech,rascals.q@froggy.pbtech
## #$ -q rascals.q
## #$ -q campagne_ctsc.q

function setup {
    if [ ! -z $SGE_O_WORKDIR ]; then
        echo ------------------------------------------------------
        echo This machines hostname: `hostname`
        echo ------------------------------------------------------
        echo SGE: qsub is running on ${SGE_O_HOST}
        echo SGE: originating queue is ${QUEUE}
        echo SGE: executing cell is ${SGE_CELL}
        echo SGE: working directory is ${SGE_O_WORKDIR}
        echo SGE: execution mode is ${ENVIRONMENT}
        echo SGE: execution host is ${HOSTNAME}
        echo SGE: job identifier is ${JOB_ID}
        echo SGE: job name is ${JOB_NAME}
        echo SGE: task number is ${SGE_TASK_ID}
        echo SGE: current home directory is ${SGE_O_HOME}
        echo SGE: scratch directory is ${TMPDIR}
        echo SGE: PATH = ${SGE_O_PATH}
        echo ------------------------------------------------------
    fi
    # For comparisons with CRAM 0.7, we use a chunk-size of 1,000,000 entries to mimic the CRAM block size (see https://github.com/vadimzalunin/crammer/blob/master/src/main/java/uk/ac/ebi/ena/sra/cram/impl/CramWriter.java maxRecordsPerBlock in version 0.7)
    CHUNK_SIZE=100000
    CHUNK="-x MessageChunksWriter:chunk-size=${CHUNK_SIZE}"
    # define input and output directories
    SRC_DIR=~/reads-for-paper/bam-files/
    DEST_DIR=~/reads-for-paper/results
    HYBRID_STATS_FILE=~/reads-for-paper/results/hybrid-stats-file.tsv
    
    # Define the available references
    REF_DIR_MOUSE_NCBIM37_MM9=/scratchLocal/gobyweb/input-data/reference-db/NCBI37.55/mus_musculus/reference
    REF_DIR_MOUSE_NCBIM37_MM9=/scratchLocal/gobyweb/input-data/reference-db/goby-benchmark-paper/mm9
    REF_FA_MOUSE_NCBIM37_MM9=mm9.fa
    
    REF_DIR_HUMAN_GRCH37_1000G=/scratchLocal/gobyweb/input-data/reference-db/1000GENOMES.37/homo_sapiens/reference
    REF_FA_HUMAN_GRCH37_1000G=human_g1k_v37.fa

    REF_DIR_MOUSE_MM8=/scratchLocal/gobyweb/input-data/reference-db/goby-benchmark-paper/MM8
    REF_FA_MOUSE_MM8=Mus_musculus.ucsc.mm8.fa

    REF_DIR_HUMAN_HG19=/scratchLocal/gobyweb/input-data/reference-db/goby-benchmark-paper/HG19
    REF_FA_HUMAN_HG19=Homo_sapiens.ucsc.hg19.fa
    
    #REF_DIR_HUMAN_NCBI36_HG18=/scratchLocal/gobyweb/input-data/reference-db/NCBI36.54/homo_sapiens/reference
    REF_DIR_HUMAN_NCBI36_HG18=/scratchLocal/gobyweb/input-data/reference-db/goby-benchmark-paper/hg18
    REF_FA_HUMAN_NCBI36_HG18=hg18.fa
    
    #REF_DIR_HZFWPTI_UANMNXR=/scratchLocal/gobyweb/input-data/reference-db/goby-benchmark-paper/HZFWPTI-UANMNXR
    #REF_FA_HZFWPTI_UANMNXR=hs375d5.fa
    
    REF_DIR_UCCWRUX_XAAOBVT=/scratchLocal/gobyweb/input-data/reference-db/goby-benchmark-paper/UCCWRUX-XAAOBVT
    REF_FA_UCCWRUX_XAAOBVT=ref.fa

    REF_DIR_CELEGANS=/scratchLocal/gobyweb/input-data/reference-db/goby-benchmark-paper/cElegans
    #REF_FA_CELEGANS=cElegans.fa uppercase version fails with cramtools
    REF_FA_CELEGANS=ce.fa # Lowercase version, not sure what cramtools does with the variations..

    # For each sample, define the reference it is assocaited with. This should be a
    REF_DIR_HZFWPTI=${REF_DIR_HUMAN_GRCH37_1000G}
    REF_FA_HZFWPTI=${REF_FA_HUMAN_GRCH37_1000G}
    SORT_HZFWPTI=false
    PAIRED_HZFWPTI=true

    REF_DIR_UANMNXR=${REF_DIR_HUMAN_GRCH37_1000G}
    REF_FA_UANMNXR=${REF_FA_HUMAN_GRCH37_1000G}
    SORT_UANMNXR=false
    PAIRED_UANMNXR=true

    REF_DIR_MYHZZJH=${REF_DIR_HUMAN_GRCH37_1000G}
    REF_FA_MYHZZJH=${REF_FA_HUMAN_GRCH37_1000G}
    SORT_MYHZZJH=true
    PAIRED_MYHZZJH=false

    REF_DIR_ZHUUJKS=${REF_DIR_HUMAN_GRCH37_1000G}
    REF_FA_ZHUUJKS=${REF_FA_HUMAN_GRCH37_1000G}
    SORT_ZHUUJKS=true
    PAIRED_ZHUUJKS=false

    REF_DIR_EJOYQAZ=${REF_DIR_HUMAN_HG19}
    REF_FA_EJOYQAZ=${REF_FA_HUMAN_HG19}
    SORT_EJOYQAZ=true
    PAIRED_EJOYQAZ=true
 
    # the next one is only used for testing. Based on EJOYQAZ to test sorting: 
    REF_DIR_SMALL=${REF_DIR_HUMAN_HG19}
    REF_FA_SMALL=${REF_FA_HUMAN_HG19}
    SORT_SMALL=true
    PAIRED_SMALL=true

    REF_DIR_JRODTYG=${REF_DIR_MOUSE_NCBIM37_MM9}
    REF_FA_JRODTYG=${REF_FA_MOUSE_NCBIM37_MM9}
    SORT_JRODTYG=true
    PAIRED_JRODTYG=false

    REF_DIR_ZVLRRJH=${REF_DIR_HUMAN_NCBI36_HG18}
    REF_FA_ZVLRRJH=${REF_FA_HUMAN_NCBI36_HG18}
    SORT_ZVLRRJH=false
    PAIRED_ZVLRRJH=false

    REF_DIR_GGNEDKP=${REF_DIR_HUMAN_NCBI36_HG18}
    REF_FA_GGNEDKP=${REF_FA_HUMAN_NCBI36_HG18}
    SORT_GGNEDKP=false
    ## No clue, I don't think we're using this dataset??
    PAIRED_GGNEDKP=false

    REF_DIR_XAAOBVT=${REF_DIR_HUMAN_NCBI36_HG18}
    REF_FA_XAAOBVT=${REF_FA_HUMAN_NCBI36_HG18}
    #REF_DIR_XAAOBVT=${REF_DIR_UCCWRUX_XAAOBVT}
    #REF_FA_XAAOBVT=${REF_FA_UCCWRUX_XAAOBVT}
    SORT_XAAOBVT=false
    PAIRED_XAAOBVT=true
    
    REF_DIR_UCCWRUX=${REF_DIR_HUMAN_NCBI36_HG18} #${REF_DIR_UCCWRUX_XAAOBVT}
    REF_FA_UCCWRUX=${REF_FA_HUMAN_NCBI36_HG18}  # ${REF_FA_UCCWRUX_XAAOBVT}
    SORT_UCCWRUX=false
    PAIRED_UCCWRUX=true

    REF_DIR_HENGLIT=${REF_DIR_CELEGANS}
    REF_FA_HENGLIT=${REF_FA_CELEGANS}
    SORT_HENGLIT=false
    PAIRED_HENGLIT=true

    ## Manually configured dependencies here
    ## such as "-hold_jid 117186"
    DEPENDS_FLAGS=""
    if [[ -e  last_jobs_pids.txt ]]; then
        DEPENDS_FLAGS="-hold_jid `cat last_jobs_pids.txt`"
    fi

    # Define the work to be done
    WORK_TAGS="HZFWPTI UANMNXR MYHZZJH ZHUUJKS EJOYQAZ JRODTYG ZVLRRJH XAAOBVT UCCWRUX HENGLIT"
    ##
    ## Order of execution
    ##
   #WORK_ACTIONS="index-bam bam-TO-bam_name_sort"  #1
   #WORK_ACTIONS="bam-TO-goby_null bam-TO-goby_hybrid_domain_noclips bam-TO-goby_gzip bam-TO-cram1 bam-TO-cram2 bam-TO-cram3" #2 
   #WORK_ACTIONS="bam-TO-goby_hybrid_keep_max" #3
   #WORK_ACTIONS="cram1-TO-bam cram2-TO-bam cram3-TO-bam goby_gzip-TO-bam goby_hybrid_domain-TO-bam goby_hybrid_keep_max-TO-bam bam-TO-bzip2_reads" #4
   #WORK_ACTIONS="goby_gzip-TO-goby_null goby_gzip-TO-goby_bzip2 goby_gzip-TO-goby_gzip goby_gzip-TO-goby_hybrid goby_gzip-TO-goby_hybrid_domain goby_gzip-TO-goby_hybrid_no_templ" #5
   #WORK_ACTIONS="goby_any-TO-goby_cfs" #6
    WORK_ACTIONS="bzip2_reads-TO-fastq_bzip2" #7
    
   #WORK_ACTIONS="bam-TO-goby_hybrid_keep_max"
   # WORK_ACTIONS="goby_gzip-TO-goby_hybrid_domain goby_gzip-TO-goby_hybrid"
    
    ##
    ## Other
    ##
    #WORK_ACTIONS="goby_gzip-TO-goby_gzip_perm bam-TO-gzip_reads goby_gzip-TO-goby_bzip2_perm goby_gzip-TO-goby_hybrid_perm_no_templ bam-TO-bam-comparison goby_gzip-TO-goby_hybrid_perm bam-stats"
    
    # Define the executables
    SAMTOOLS=~/goby-dev/nextgen-tools/samtools-0.1.14/samtools
    SAMSTAT=~/goby-dev/nextgen-tools/samstat/samstat
    PSORT=~/local-lib/bin/psort.sh
    JAVA_MEM=6g
    #JAVA_MEM=10g
    #JAVA_MEM=2g
    # Question: Perhaps use -XX:+UseConcMarkSweepGC  for ??
    GOBY_JAR=~/reads-for-paper/goby.jar
    CRAMTOOLS_JAR=~/goby-dev/nextgen-tools/cramtools-0.7/cramtools.jar
    echo GOBY version=`java -jar ${GOBY_JAR} -m version`
    CRAM_OPTIONS1="--ignore-soft-clips --exclude-unmapped-placed-reads"
    CRAM_OPTIONS2="--capture-substitution-quality-scores --capture-insertion-quality-scores"
    CRAM_OPTIONS3="--capture-all-tags --capture-all-quality-scores"
    
    if [[ "${TAG}" != "" ]]; then
        # If we are actually running a job, move to the local temp work dir
        cd ${TMPDIR}
    echo Current directory is `pwd`

        # Define the output directory to save anything that was created
        if [[ "${ACTION_SUB_DIR}" != "" ]]; then
            FINAL_OUTPUT_DIR=${DEST_DIR}/${WORK_ACTION}_${ACTION_SUB_DIR}/${TAG}/
        else
            FINAL_OUTPUT_DIR=${DEST_DIR}/${WORK_ACTION}/${TAG}/
        fi
        echo Set FINAL_OUTPUT_DIR=${FINAL_OUTPUT_DIR}
        mkdir -p ${FINAL_OUTPUT_DIR}
        
        # Define the local reference dir and reference fasta for this tag.
        # based on the above values.
        eval REF_DIR=\$REF_DIR_${TAG}
        eval REF_FA=\$REF_FA_${TAG}

        cp ${GOBY_JAR} .
        cp ${CRAMTOOLS_JAR} .
        cp ~/reads-for-paper/log4j.properties .

        GOBY_EXEC_MODE="java -ea -Xmx${JAVA_MEM} -Xms${JAVA_MEM} -Dlog4j.configuration=file:log4j.properties -jar goby.jar -m"
        CRAMTOOLS_EXEC="java -ea -Xmx${JAVA_MEM} -Xms${JAVA_MEM} -jar cramtools.jar"
    fi
}

function copy_results {
    if [[ "${FINAL_OUTPUT_DIR}" != "" ]]; then
        rm *.jar log4j.properties
        cp -R * ${FINAL_OUTPUT_DIR}
        ls -lath ${FINAL_OUTPUT_DIR}
        echo "."
        echo "."
        echo ". Statistics"
        echo "."
        echo "."
        echo ":compact alignment sizes"
        echo `ls -lat ${FINAL_OUTPUT_DIR}/ | sumLsLat.groovy 2>/dev/null`
        echo ":bits per base"
        realBitsPerBases.groovy ${FINAL_OUTPUT_DIR}/*compact-file-stats.txt
    fi
}

#######################################################################################
## Script logic starts here
#######################################################################################

function bam-stats {
    cp ${SRC_DIR}/${TAG}.bam .
    echo "+++"
    echo "+++ Timing BAM file stats using samstats ${TAG}"
    echo "+++"
    time ${SAMSTAT} ${TAG}.bam
    # Remove any files we don't want to archive when this is done.
    # ** Don't keep the source bam file
    rm ${TAG}.bam
}

function bam-TO-gzip_reads {
    cp ${DEST_DIR}/bam-TO-bam_name_sort/${TAG}/${TAG}*.bam .
    echo "+++"
    echo "+++ Timing BAM to gzip reads ${TAG}"
    echo "+++"
    time ${GOBY_EXEC_MODE} ser -o ${TAG}.compact-reads ${TAG}*.bam 
    RETURN_STATUS=$?
    if [ ! $RETURN_STATUS -eq 0 ]; then
        echo "Job seems to have failed with return status ${RETURN_STATUS}"
        exit
    fi

    ${GOBY_EXEC_MODE} cfs ${TAG}.compact-reads > ${TAG}.compact-file-stats.txt
    # Remove any files we don't want to archive when this is done.
    # ** Don't keep the source bam file
    rm ${TAG}*.bam 
}

function bzip2_reads-TO-fastq_bzip2 {
    cp ${DEST_DIR}/bam-TO-bzip2_reads/${TAG}/${TAG}.compact-reads .

    eval PAIRED_END=\$PAIRED_${TAG}
    PAIRED_OPTION=""
    if [ ${PAIRED_END} == true ]; then
        PAIRED_OPTION="-p ${TAG}-pair.fastq"
    fi

    echo "+++"
    echo "+++ Timing BAM to bzip2 reads ${TAG}"
    echo "+++"
    time ${GOBY_EXEC_MODE} ctf \
        -i ${TAG}.compact-reads \
        -o ${TAG}.fastq ${PAIRED_OPTION} \
        ${CHUNK} \
        -t fastq
    RETURN_STATUS=$?
    if [ ! $RETURN_STATUS -eq 0 ]; then
        echo "Job seems to have failed with return status ${RETURN_STATUS}"
        exit
    fi
    mv ${TAG}.fastq ${TAG}-1.fastq
    bzip2 ${TAG}-1.fastq 
    mv ${TAG}-1.fastq.bz2 ${TAG}.1_fq_bz2
 
    if [ ${PAIRED_END} == true ]; then
       mv ${TAG}-pair.fastq ${TAG}-2.fastq
       bzip2 ${TAG}-2.fastq
       mv  ${TAG}-2.fastq.bz2  ${TAG}.2_fq_bz2
    fi
    
    # Remove any files we don't want to archive when this is done.
    # ** Don't keep the source compact-reads file
    rm ${TAG}.compact-reads
}

function bam-TO-bzip2_reads {
    cp ${DEST_DIR}/bam-TO-bam_name_sort/${TAG}/${TAG}*.bam .
    echo "+++"
    echo "+++ Timing BAM to bzip2 reads ${TAG}"
    echo "+++"
    time ${GOBY_EXEC_MODE} ser -o ${TAG}.compact-reads ${TAG}*.bam -x MessageChunksWriter:codec=bzip2 
    RETURN_STATUS=$?
    if [ ! $RETURN_STATUS -eq 0 ]; then
        echo "Job seems to have failed with return status ${RETURN_STATUS}"
        exit
    fi

    # Remove any files we don't want to archive when this is done.
    # ** Don't keep the source bam file
    rm ${TAG}*.bam 
}

function bam-TO-goby_null {
    cp ${SRC_DIR}/${TAG}-no-unmapped.bam .
    echo "+++"
    echo "+++ Timing BAM to Goby-NULL ${TAG}"
    echo "+++"
    time ${GOBY_EXEC_MODE} stc --number-of-reads 0 -i ${TAG}-no-unmapped.bam -o ${TAG} -x MessageChunksWriter:codec=null -x AlignmentWriterImpl:permutate-query-indices=false -x SAMToCompactMode:ignore-read-origin=true  --preserve-soft-clips 
    RETURN_STATUS=$?
    if [ ! $RETURN_STATUS -eq 0 ]; then
        echo "Job seems to have failed with return status ${RETURN_STATUS}"
        exit
    fi

    # Remove any files we don't want to archive when this is done.
    # ** Don't keep the source bam file
    rm ${TAG}.bam 
}

function index-bam {
    echo "+++"
    echo "+++ Timing indexing BAM ${TAG}"
    echo "+++"
    time ${SAMTOOLS} index ${SRC_DIR}/${TAG}-no-unmapped.bam
}

function bam-TO-bam_name_sort {
    cp ${SRC_DIR}/${TAG}.bam* .
    ${SAMTOOLS} sort -n ${TAG}.bam ${TAG}.name-sorted
    rm ${TAG}.bam ${TAG}.bam.bai
}

function bam-TO-cram1 {
    cp ${SRC_DIR}/${TAG}-no-unmapped.bam* .
    echo "+++"
    echo "+++ Timing BAM to CRAM most lossy ${TAG}"
    echo "+++"
    time ${CRAMTOOLS_EXEC} cram --input-bam-file ${TAG}-no-unmapped.bam --reference-fasta-file ${REF_DIR}/${REF_FA} --output-cram-file ${TAG}.cram ${CRAM_OPTIONS1}
    RETURN_STATUS=$?
    if [ ! $RETURN_STATUS -eq 0 ]; then
        echo "Job seems to have failed with return status ${RETURN_STATUS}"
        exit
    fi
    ${CRAMTOOLS_EXEC} index   --input-cram-file ${TAG}.cram  --reference-fasta-file ${REF_DIR}/${REF_FA}
    if [ ! $RETURN_STATUS -eq 0 ]; then
        echo "Job seems to have failed with return status ${RETURN_STATUS}"
        exit
    fi
    # Remove any files we don't want to archive when this is done.
    # ** Don't keep the source bam file
    rm ${TAG}*.bam ${TAG}*.bam.bai
}


function bam-TO-cram2 {
    cp ${SRC_DIR}/${TAG}-no-unmapped.bam* .
    echo "+++"
    echo "+++ Timing BAM to CRAM somewhat lossless ${TAG}"
    echo "+++"
    ls
    time ${CRAMTOOLS_EXEC} cram --input-bam-file ${TAG}-no-unmapped.bam --reference-fasta-file ${REF_DIR}/${REF_FA} --output-cram-file ${TAG}.cram ${CRAM_OPTIONS2}
    RETURN_STATUS=$?
    if [ ! $RETURN_STATUS -eq 0 ]; then
        echo "Job seems to have failed with return status ${RETURN_STATUS}"
        exit
    fi
    ${CRAMTOOLS_EXEC} index   --input-cram-file ${TAG}.cram  --reference-fasta-file ${REF_DIR}/${REF_FA} 
    if [ ! $RETURN_STATUS -eq 0 ]; then
        echo "Job seems to have failed with return status ${RETURN_STATUS}"
        exit
    fi
    
    # Remove any files we don't want to archive when this is done.
    # ** Don't keep the source bam file
    rm ${TAG}*.bam ${TAG}*.bam.bai
}

function bam-TO-cram3 {
    cp ${SRC_DIR}/${TAG}-no-unmapped.bam* .
    echo "+++"
    echo "+++ Timing BAM to CRAM most lossless ${TAG}"
    echo "+++"
    time ${CRAMTOOLS_EXEC} cram --input-bam-file ${TAG}-no-unmapped.bam --reference-fasta-file ${REF_DIR}/${REF_FA} --output-cram-file ${TAG}.cram ${CRAM_OPTIONS3}
    RETURN_STATUS=$?
    if [ ! $RETURN_STATUS -eq 0 ]; then
        echo "Job seems to have failed with return status ${RETURN_STATUS}"
        exit
    fi
    ${CRAMTOOLS_EXEC} index   --input-cram-file ${TAG}.cram  --reference-fasta-file ${REF_DIR}/${REF_FA}
    if [ ! $RETURN_STATUS -eq 0 ]; then
        echo "Job seems to have failed with return status ${RETURN_STATUS}"
        exit
    fi

    # Remove any files we don't want to archive when this is done.
    # ** Don't keep the source bam file
    rm ${TAG}*.bam ${TAG}*.bam.bai
}

function cram1-TO-bam {
    cp ${DEST_DIR}/bam-TO-cram1/${TAG}/${TAG}.cram .
    echo "+++"
    echo "+++ Timing CRAM1 to BAM most lossy ${TAG}"
    echo "+++"
    time ${CRAMTOOLS_EXEC} bam --input-cram-file ${TAG}.cram --reference-fasta-file ${REF_DIR}/${REF_FA} --output-bam-file ${TAG}-from-cram1.bam --calculate-md-tag
    RETURN_STATUS=$?
    if [ ! $RETURN_STATUS -eq 0 ]; then
        echo "Job seems to have failed with return status ${RETURN_STATUS}"
        exit
    fi
    # Remove any files we don't want to archive when this is done.
    rm ${TAG}.cram
}

function cram2-TO-bam {
    cp ${DEST_DIR}/bam-TO-cram2/${TAG}/${TAG}.cram .
    echo "+++"
    echo "+++ Timing CRAM2 to BAM somewhat lossless ${TAG}"
    echo "+++"
    time ${CRAMTOOLS_EXEC} bam --input-cram-file ${TAG}.cram --reference-fasta-file ${REF_DIR}/${REF_FA} --output-bam-file ${TAG}-from-cram2.bam --calculate-md-tag
    RETURN_STATUS=$?
    if [ ! $RETURN_STATUS -eq 0 ]; then
        echo "Job seems to have failed with return status ${RETURN_STATUS}"
        exit
    fi
    # Remove any files we don't want to archive when this is done.
    rm ${TAG}.cram
}

function cram3-TO-bam {
    cp ${DEST_DIR}/bam-TO-cram3/${TAG}/${TAG}.cram .
    echo "+++"
    echo "+++ Timing CRAM3 to BAM most lossless ${TAG}"
    echo "+++"
    time ${CRAMTOOLS_EXEC} bam --input-cram-file ${TAG}.cram --reference-fasta-file ${REF_DIR}/${REF_FA} --output-bam-file ${TAG}-from-cram3.bam --calculate-md-tag
    RETURN_STATUS=$?
    if [ ! $RETURN_STATUS -eq 0 ]; then
        echo "Job seems to have failed with return status ${RETURN_STATUS}"
        exit
    fi
    # Remove any files we don't want to archive when this is done.
    rm ${TAG}.cram
}


function compact_file_stats { 
    ${GOBY_EXEC_MODE} cfs ${TAG}.entries > ${TAG}.compact-file-stats.txt
}

function bam-TO-goby_hybrid_keep_max {
    cp ${SRC_DIR}/${TAG}-no-unmapped.bam .
    echo "+++"
    echo "+++ Timing converting BAM to bam-TO-goby_hybrid_keep_max ${TAG}"
    echo "+++"

    GENOME_OPT="-g ${REF_DIR}/random-access-genome "
    eval NEED_SORT=\$SORT_${TAG}

    if [ ${NEED_SORT} == true ]; then
        POST_FIX="-pre-sort"
        SORTED_OPTION=""
    else
        POST_FIX="-sorted"
        SORTED_OPTION="--sorted"
    fi

    time ${GOBY_EXEC_MODE} stc ${GENOME_OPT} ${SORTED_OPTION} -i ${TAG}-no-unmapped.bam \
         -o ${TAG}${POST_FIX} --preserve-all-mapped-qualities  \
          --preserve-all-tags --preserve-soft-clips ${CHUNK}
    RETURN_STATUS=$?
    if [ ! $RETURN_STATUS -eq 0 ]; then
        echo "Job seems to have failed with return status ${RETURN_STATUS}"
        exit
    fi
    if [ ${NEED_SORT} == true ]; then
        ${GOBY_EXEC_MODE} sort --temp-dir /tmp ${TAG}${POST_FIX}  -o ${TAG}-sorted -t 0 -s 10000000
        RETURN_STATUS=$?
        if [ ! $RETURN_STATUS -eq 0 ]; then
            echo "Job sort seems to have failed with return status ${RETURN_STATUS}"
            exit
        fi
        rm -f ${TAG}${POST_FIX}.*
    fi
    ${GOBY_EXEC_MODE} ca ${TAG}-sorted -o ${TAG} \
        -x AlignmentWriterImpl:permutate-query-indices=false \
        -x SAMToCompactMode:ignore-read-origin=false \
        -x MessageChunksWriter:codec=hybrid-1 \
        -x AlignmentCollectionHandler:enable-domain-optimizations=true \
        -x MessageChunksWriter:compressing-codec=true
    RETURN_STATUS=$?
    if [ ! $RETURN_STATUS -eq 0 ]; then
            echo "Job sort seems to have failed with return status ${RETURN_STATUS}"
                exit        
    fi    
    rm -f ${TAG}-*.*
    if [ ! $RETURN_STATUS -eq 0 ]; then
        echo "Job sort seems to have failed with return status ${RETURN_STATUS}"
                exit
    fi

    compact_file_stats
    # Remove any files we don't want to archive when this is done.
    # ** Don't keep the source bam file, the rest should be copied
    rm -f ${TAG}.bam
}

function bam-TO-goby_gzip {
    cp ${SRC_DIR}/${TAG}-no-unmapped.bam .
    echo "+++"
    echo "+++ Timing converting BAM to goby_gzip ${TAG}"
    echo "+++"
  
    GENOME_OPT="-g ${REF_DIR}/random-access-genome "
    eval NEED_SORT=\$SORT_${TAG}

    if [ ${NEED_SORT} == true ]; then
        POST_FIX="-pre-sort"
        SORTED_OPTION=""
    else
        POST_FIX=""
        SORTED_OPTION="--sorted"
    fi
    time ${GOBY_EXEC_MODE} stc ${GENOME_OPT} ${SORTED_OPTION} -i ${TAG}-no-unmapped.bam \
       -o ${TAG}${POST_FIX} \
       -x SAMToCompactMode:ignore-read-origin=false --preserve-soft-clips ${CHUNK}
    RETURN_STATUS=$?
    if [ ! $RETURN_STATUS -eq 0 ]; then
        echo "Job seems to have failed with return status ${RETURN_STATUS}"
        exit
    fi
    if [ ${NEED_SORT} == true ]; then
        ${GOBY_EXEC_MODE} sort --temp-dir /tmp ${TAG}${POST_FIX} -o ${TAG} -t 0 -s 10000000
        RETURN_STATUS=$?
        if [ ! $RETURN_STATUS -eq 0 ]; then
            echo "Job sort seems to have failed with return status ${RETURN_STATUS}"
            exit        
        fi
        rm -f ${TAG}${POST_FIX}.* 
    fi
        
    compact_file_stats
    # Remove any files we don't want to archive when this is done.
    # ** Don't keep the source bam file, the rest should be copied
    rm -f ${TAG}*.bam
}
function bam-TO-goby_hybrid_domain_noclips {
    cp ${SRC_DIR}/${TAG}-no-unmapped.bam .
    echo "+++"
    echo "+++ Timing converting BAM to goby_hybrid_domain_noclips ${TAG}"
    echo "+++"
  
    GENOME_OPT="-g ${REF_DIR}/random-access-genome "
    eval NEED_SORT=\$SORT_${TAG}
    
    if [ ${NEED_SORT} == true ]; then
        POST_FIX="-pre-sort"
        SORTED_OPTION=""
    else
        POST_FIX="-pre-hybrid"
        SORTED_OPTION="--sorted"
    fi
    time ${GOBY_EXEC_MODE} stc ${GENOME_OPT} ${SORTED_OPTION} -i ${TAG}-no-unmapped.bam \
       -o ${TAG}${POST_FIX} \
       -x SAMToCompactMode:ignore-read-origin=false  ${CHUNK}
    RETURN_STATUS=$?
    if [ ! $RETURN_STATUS -eq 0 ]; then
        echo "Job seems to have failed with return status ${RETURN_STATUS}"
        exit
    fi
    if [ ${NEED_SORT} == true ]; then
        ${GOBY_EXEC_MODE} sort --temp-dir /tmp ${TAG}${POST_FIX} -o ${TAG}-pre-hybrid -t 0 -s 10000000
        RETURN_STATUS=$?
        if [ ! $RETURN_STATUS -eq 0 ]; then
            echo "Job sort seems to have failed with return status ${RETURN_STATUS}"
            exit        
        fi
        rm -f ${TAG}${POST_FIX}.* 
    fi
    ${GOBY_EXEC_MODE} ca ${TAG}-pre-hybrid -o ${TAG} \
	${CHUNK} \
        -x AlignmentWriterImpl:permutate-query-indices=false \
        -x SAMToCompactMode:ignore-read-origin=false \
        -x MessageChunksWriter:codec=hybrid-1 \
        -x AlignmentCollectionHandler:enable-domain-optimizations=true \
        -x MessageChunksWriter:compressing-codec=true
    RETURN_STATUS=$?
    if [ ! $RETURN_STATUS -eq 0 ]; then
            echo "Job sort seems to have failed with return status ${RETURN_STATUS}"
                exit        
    fi    
    rm -f ${TAG}-*.*
    
    compact_file_stats
    # Remove any files we don't want to archive when this is done.
    # ** Don't keep the source bam file, the rest should be copied
    rm -f ${TAG}*.bam
}
function bam-TO-bam-comparison {
    mkdir src-bam
    mkdir dest-goby
    mkdir dest-bam
    cp ${SRC_DIR}/${TAG}-no-unmapped.bam src-bam/
    cp ${DEST_DIR}/bam-TO-goby_gzip/${TAG}/${TAG}.* dest-goby/
    cp ${DEST_DIR}/goby_hybrid_domain-TO-bam/${TAG}/${TAG}.bam dest-bam/
    echo "+++"
    echo "+++ Timing bam-TO-bam-comparison ${TAG}"
    echo "+++"
    time ${GOBY_EXEC_MODE} sc \
        --source-bam src-bam/${TAG}-no-unmapped.bam \
        --destination-bam dest-bam/${TAG}.bam \
        --soft-clips-preserved true \
        --canonical-mdz true > ${TAG}-bam-diffs.txt
    ${SAMTOOLS} view -h src-bam/${TAG}-no-unmapped.bam |head -10000 >${TAG}-source-10000.sam 
    ${SAMTOOLS} view -h dest-bam/${TAG}.bam |head -10000 >${TAG}-destination-10000.sam 

    # Remove any files we don't want to archive when this is done.
    rm -rf src-bam dest-goby dest-bam
}

function goby_gzip-TO-bam {
    cp ${DEST_DIR}/bam-TO-goby_gzip/${TAG}/${TAG}*.* .
    echo "+++"
    echo "+++ Timing performing goby_gzip to bam for ${TAG}"
    echo "+++"
    time ${GOBY_EXEC_MODE} cts -o ${TAG}.bam -g ${REF_DIR}/random-access-genome ${TAG}*.entries
    RETURN_STATUS=$?
    if [ ! $RETURN_STATUS -eq 0 ]; then
        echo "Job seems to have failed with return status ${RETURN_STATUS}"
        exit
    fi
    echo "+++"
    echo "+++ Indexing .bam file, NOT TIMING"
    echo "+++"
    ${SAMTOOLS} index ${TAG}.bam
    # Remove any files we don't want to archive when this is done.
    rm ${TAG}*.header ${TAG}*.stats ${TAG}*.entries ${TAG}*.index ${TAG}*.tmh
}

function goby_hybrid_domain-TO-bam {
    cp ${DEST_DIR}/goby_gzip-TO-goby_hybrid_domain/${TAG}/${TAG}*.* .
    echo "+++"
    echo "+++ Timing performing goby_hybrid to bam for ${TAG}"
    echo "+++"
    time ${GOBY_EXEC_MODE} cts -o ${TAG}.bam -g ${REF_DIR}/random-access-genome ${TAG}*.entries 
    RETURN_STATUS=$?
    if [ ! $RETURN_STATUS -eq 0 ]; then
        echo "Job seems to have failed with return status ${RETURN_STATUS}"
        exit
    fi
    # Remove any files we don't want to archive when this is done.
    rm ${TAG}*.header ${TAG}*.stats ${TAG}*.entries ${TAG}*.index ${TAG}*.tmh
}

function goby_hybrid_keep_max-TO-bam {
    cp ${DEST_DIR}/bam-TO-goby_hybrid_keep_max/${TAG}/${TAG}*.* .
    echo "+++"
    echo "+++ Timing performing goby_hybrid_keep_max to bam for ${TAG}"
    echo "+++"
    time ${GOBY_EXEC_MODE} cts -o ${TAG}.bam -g ${REF_DIR}/random-access-genome ${TAG}*.entries 
    RETURN_STATUS=$?
    if [ ! $RETURN_STATUS -eq 0 ]; then
        echo "Job seems to have failed with return status ${RETURN_STATUS}"
        exit
    fi
    # Remove any files we don't want to archive when this is done.
    rm ${TAG}*.header ${TAG}*.stats ${TAG}*.entries ${TAG}*.index ${TAG}*.tmh
}



function goby_gzip-TO-goby_gzip {
    cp ${DEST_DIR}/bam-TO-goby_gzip/${TAG}/${TAG}.* .
    echo "+++"
    echo "+++ Timing performing goby_gzip to goby_gzip for ${TAG}"
    echo "+++"
    time ${GOBY_EXEC_MODE} ca ${TAG}.entries -o ${TAG}-gzip -x MessageChunksWriter:codec=gzip -x AlignmentWriterImpl:permutate-query-indices=false
    RETURN_STATUS=$?
    if [ ! $RETURN_STATUS -eq 0 ]; then
        echo "Job seems to have failed with return status ${RETURN_STATUS}"
        exit
    fi
    ${GOBY_EXEC_MODE} cfs ${TAG}-gzip.entries > ${TAG}-gzip.compact-file-stats.txt
    # Remove any files we don't want to archive when this is done.
    rm ${TAG}.*
}

function goby_any-TO-goby_cfs { 
    cp ${DEST_DIR}/goby_gzip-TO-goby_${ACTION_SUB_DIR}/${TAG}/${TAG}* .
    echo "+++"
    echo "+++ Timing goby_gzip_${ACTION_SUB_DIR} compact-file-stats ${TAG}"
    echo "+++"
    time ${GOBY_EXEC_MODE} cfs ${TAG}*.entries > ${TAG}.compact-file-stats.txt
    RETURN_STATUS=$?
    if [ ! $RETURN_STATUS -eq 0 ]; then
        echo "Job seems to have failed with return status ${RETURN_STATUS}"
        exit
    fi
    # Remove any files we don't want to archive when this is done.
    rm ${TAG}*.header ${TAG}*.stats ${TAG}*.entries ${TAG}*.index ${TAG}*.tmh
}

function goby_gzip-TO-goby_null {
    cp ${DEST_DIR}/bam-TO-goby_gzip/${TAG}/${TAG}.* .
    echo "+++"
    echo "+++ Timing converting goby_gzip to goby_null ${TAG}"
    echo "+++"
    time ${GOBY_EXEC_MODE} ca ${TAG}.entries -o ${TAG}-null -x MessageChunksWriter:codec=null -x AlignmentWriterImpl:permutate-query-indices=false
    RETURN_STATUS=$?
    if [ ! $RETURN_STATUS -eq 0 ]; then
        echo "Job seems to have failed with return status ${RETURN_STATUS}"
        exit
    fi
    compact_file_stats
    # Remove any files we don't want to archive when this is done.
    rm ${TAG}.header ${TAG}.stats ${TAG}.entries ${TAG}.index ${TAG}.tmh
}

function goby_gzip-TO-goby_gzip_perm {
    cp ${DEST_DIR}/bam-TO-goby_gzip/${TAG}/${TAG}.* .
    echo "+++"
    echo "+++ Timing performing goby_gzip to goby_gzip_perm for ${TAG}"
    echo "+++"
    time ${GOBY_EXEC_MODE} ca ${TAG}.entries -o ${TAG}-gzip-perm -x MessageChunksWriter:codec=gzip -x AlignmentWriterImpl:permutate-query-indices=true \
         ${CHUNK}
    RETURN_STATUS=$?
    if [ ! $RETURN_STATUS -eq 0 ]; then
        echo "Job seems to have failed with return status ${RETURN_STATUS}"
        exit
    fi
    ${GOBY_EXEC_MODE} cfs ${TAG}-gzip-perm.entries > ${TAG}-gzip-perm.compact-file-stats.txt
    # Remove any files we don't want to archive when this is done.
    rm ${TAG}.*
}

function goby_gzip-TO-goby_bzip2 {
    cp ${DEST_DIR}/bam-TO-goby_gzip/${TAG}/${TAG}.* .
    echo "+++"
    echo "+++ Timing performing goby_gzip to goby_bzip2 for ${TAG}"
    echo "+++"
    time ${GOBY_EXEC_MODE} ca ${TAG}.entries -o ${TAG}-bzip2 -x MessageChunksWriter:codec=bzip2 -x AlignmentWriterImpl:permutate-query-indices=false ${CHUNK}
    RETURN_STATUS=$?
    if [ ! $RETURN_STATUS -eq 0 ]; then
        echo "Job seems to have failed with return status ${RETURN_STATUS}"
        exit
    fi
    ${GOBY_EXEC_MODE} cfs ${TAG}-bzip2.entries > ${TAG}-bzip2.compact-file-stats.txt
    # Remove any files we don't want to archive when this is done.
    rm ${TAG}.*
}

function goby_gzip-TO-goby_bzip2_perm {
    cp ${DEST_DIR}/bam-TO-goby_gzip/${TAG}/${TAG}.* .
    echo "+++"
    echo "+++ Timing performing goby_gzip to goby_bzip2_perm for ${TAG}"
    echo "+++"
    time ${GOBY_EXEC_MODE} ca ${TAG}.entries -o ${TAG}-bzip2-perm -x MessageChunksWriter:codec=bzip2 -x AlignmentWriterImpl:permutate-query-indices=true ${CHUNK}

    RETURN_STATUS=$?
    if [ ! $RETURN_STATUS -eq 0 ]; then
        echo "Job seems to have failed with return status ${RETURN_STATUS}"
        exit
    fi
    ${GOBY_EXEC_MODE} cfs ${TAG}-bzip2-perm.entries > ${TAG}-bzip2-perm.compact-file-stats.txt
    # Remove any files we don't want to archive when this is done.
    rm ${TAG}.*
}
function goby_gzip-TO-goby_hybrid {
    cp ${DEST_DIR}/bam-TO-goby_gzip/${TAG}/${TAG}.* .
    echo "+++"
    echo "+++ Timing performing goby_gzip to goby_hybrid for ${TAG}"
    echo "+++"
    touch ~/reads-for-paper/results/hybrid-stats-file-${TAG}.tsv
    time ${GOBY_EXEC_MODE} ca ${TAG}.entries -o ${TAG}-hybrid \
    ${CHUNK} \
        -x MessageChunksWriter:codec=hybrid-1 \
        -x AlignmentCollectionHandler:enable-domain-optimizations=false \
        -x MessageChunksWriter:template-compression=true \
        -x AlignmentCollectionHandler:ignore-read-origin=false # For comparision with CRAM since it does store SAM RG attributes by default.

    RETURN_STATUS=$?
    if [ ! $RETURN_STATUS -eq 0 ]; then
        echo "Job seems to have failed with return status ${RETURN_STATUS}"
        exit
    fi
    ${GOBY_EXEC_MODE} cfs ${TAG}-hybrid.entries > ${TAG}-hybrid.compact-file-stats.txt
    # Remove any files we don't want to archive when this is done.
    rm ${TAG}.*
}
# H+T+D method (hybrid, template, domain):
function goby_gzip-TO-goby_hybrid_domain {
    cp ${DEST_DIR}/bam-TO-goby_gzip/${TAG}/${TAG}.* .
    echo "+++"
    echo "+++ Timing performing goby_gzip to goby_hybrid_domain for ${TAG}"
    echo "+++"
    touch ~/reads-for-paper/results/hybrid-stats-file-${TAG}.tsv
    time ${GOBY_EXEC_MODE} ca ${TAG}.entries -o ${TAG}-hybrid-domain \
        ${CHUNK} \
        -x MessageChunksWriter:codec=hybrid-1 \
        -x AlignmentCollectionHandler:enable-domain-optimizations=true \
        -x AlignmentCollectionHandler:debug-level=0 \
        -x AlignmentCollectionHandler:basename=${TAG} \
        -x AlignmentCollectionHandler:stats-filename=/home/gobyweb/reads-for-paper/results/hybrid_domain-stats-file-${TAG}.tsv \
        -x MessageChunksWriter:template-compression=true \
        -x AlignmentCollectionHandler:ignore-read-origin=false # For comparision with CRAM since it does store RG SAM attributes by default.

    RETURN_STATUS=$?
    if [ ! $RETURN_STATUS -eq 0 ]; then
        echo "Job seems to have failed with return status ${RETURN_STATUS}"
        exit
    fi
    ${GOBY_EXEC_MODE} cfs ${TAG}-hybrid-domain.entries > ${TAG}-hybrid-domain.compact-file-stats.txt
    # Remove any files we don't want to archive when this is done.
    rm ${TAG}.*
}


function goby_gzip-TO-goby_hybrid_perm {
    cp ${DEST_DIR}/bam-TO-goby_gzip/${TAG}/${TAG}.* .
    echo "+++"
    echo "+++ Timing performing goby_gzip to goby_hybrid_perm for ${TAG}"
    echo "+++"
    touch ~/reads-for-paper/results/hybrid-stats-file-${TAG}.tsv
    time ${GOBY_EXEC_MODE} ca ${TAG}.entries -o ${TAG}-hybrid-perm \
        -x MessageChunksWriter:codec=hybrid-1 \
        ${CHUNK} \
        -x AlignmentWriterImpl:permutate-query-indices=true \
        -x AlignmentCollectionHandler:debug-level=0 \
        -x AlignmentCollectionHandler:basename=${TAG} \
        -x AlignmentCollectionHandler:stats-filename=/home/gobyweb/reads-for-paper/results/hybrid-stats-file-${TAG}.tsv \
        -x AlignmentCollectionHandler:ignore-read-origin=false # For comparision with CRAM since it does store RG SAM attributes by default.
    RETURN_STATUS=$?
    if [ ! $RETURN_STATUS -eq 0 ]; then
        echo "Job seems to have failed with return status ${RETURN_STATUS}"
        exit
    fi
    ${GOBY_EXEC_MODE} cfs ${TAG}-hybrid-perm.entries > ${TAG}-hybrid-perm.compact-file-stats.txt
    # Remove any files we don't want to archive when this is done.
    rm ${TAG}.*
}

# H method (no template, no domain optimizations):
function goby_gzip-TO-goby_hybrid_no_templ {
    cp ${DEST_DIR}/bam-TO-goby_gzip/${TAG}/${TAG}.* .
    echo "+++"
    echo "+++ Timing performing goby_gzip to goby_hybrid_no_templ for ${TAG}"
    echo "+++"
    touch ~/reads-for-paper/results/hybrid-stats-file-no-template-${TAG}.tsv
    time ${GOBY_EXEC_MODE} ca ${TAG}.entries -o ${TAG}-hybrid-no-templ -x MessageChunksWriter:codec=hybrid-1 \
        -x AlignmentWriterImpl:permutate-query-indices=false -x MessageChunksWriter:template-compression=false -x AlignmentCollectionHandler:basename=${TAG} \
        -x AlignmentCollectionHandler:debug-level=0 \
        -x AlignmentCollectionHandler:enable-domain-optimizations=false \
        ${CHUNK} \
        -x AlignmentCollectionHandler:stats-filename=/home/gobyweb/reads-for-paper/results/hybrid-stats-file-no-template-${TAG}.tsv \
        -x AlignmentCollectionHandler:ignore-read-origin=false

    RETURN_STATUS=$?
    if [ ! $RETURN_STATUS -eq 0 ]; then
        echo "Job seems to have failed with return status ${RETURN_STATUS}"
        exit
    fi
    ${GOBY_EXEC_MODE} cfs ${TAG}-hybrid-no-templ.entries > ${TAG}-hybrid-no-templ.compact-file-stats.txt
    # Remove any files we don't want to archive when this is done.
    rm ${TAG}.*
}

function goby_gzip-TO-goby_hybrid_perm_no_templ {
    cp ${DEST_DIR}/bam-TO-goby_gzip/${TAG}/${TAG}.* .
    echo "+++"
    echo "+++ Timing performing goby_gzip to goby_hybrid_perm_no_templ for ${TAG}"
    echo "+++"
    touch ~/reads-for-paper/results/hybrid-stats-file-no-template-${TAG}.tsv
    time ${GOBY_EXEC_MODE} ca ${TAG}.entries -o ${TAG}-hybrid-perm-no-templ -x MessageChunksWriter:codec=hybrid-1 \
        ${CHUNK} \
        -x AlignmentWriterImpl:permutate-query-indices=true -x MessageChunksWriter:template-compression=false -x AlignmentCollectionHandler:basename=${TAG} \
        -x AlignmentCollectionHandler:debug-level=0 \
        -x AlignmentCollectionHandler:stats-filename=/home/gobyweb/reads-for-paper/results/hybrid-stats-file-no-template-${TAG}.tsv \
        -x AlignmentCollectionHandler:ignore-read-origin=false

    RETURN_STATUS=$?
    if [ ! $RETURN_STATUS -eq 0 ]; then
        echo "Job seems to have failed with return status ${RETURN_STATUS}"
        exit
    fi
    ${GOBY_EXEC_MODE} cfs ${TAG}-hybrid-perm-no-templ.entries > ${TAG}-hybrid-perm-no-templ.compact-file-stats.txt
    # Remove any files we don't want to archive when this is done.
    rm ${TAG}.*
}

function submit {
    echo "Submitting jobs..."
    CURRENT_SCRIPT=$0
    JOB_NOS=""
    for WORK_TAG in ${WORK_TAGS}
    do
        for WORK_ACTION in ${WORK_ACTIONS}
        do
            if [[ ${WORK_ACTION} == "goby_any-TO-goby_cfs" ]]; then
                #ACTION_SUB_DIRS="gzip gzip_perm bzip2 bzip2_perm hybrid hybrid_perm hybrid_no_templ hybrid_perm_no_templ hybrid_domain"
                ACTION_SUB_DIRS="gzip bzip2 hybrid hybrid_domain hybrid_no_templ"
                for ACTION_SUB_DIR in ${ACTION_SUB_DIRS}
                do
                    JOB_NAME="${WORK_TAG}-${WORK_ACTION}-${ACTION_SUB_DIR}"
                    echo "Submitting job ${JOB_NAME} using script ${CURRENT_SCRIPT}"
                    JOB_NO=`qsub -N ${JOB_NAME} ${DEPENDS_FLAGS} -terse -v WORK_ACTION=${WORK_ACTION} -v TAG=${WORK_TAG} -v ACTION_SUB_DIR=${ACTION_SUB_DIR} ${CURRENT_SCRIPT}`
                    add_job_no
                done
            else
                JOB_NAME="${WORK_TAG}-${WORK_ACTION}"
                echo "Submitting job ${JOB_NAME} using script ${CURRENT_SCRIPT}"
                JOB_NO=`qsub -N ${JOB_NAME} ${DEPENDS_FLAGS} -terse -v WORK_ACTION=${WORK_ACTION} -v TAG=${WORK_TAG} ${CURRENT_SCRIPT}`
                add_job_no
            fi
        done
    done
    rm -f last_jobs_pids.txt
    echo ${JOB_NOS} > last_jobs_pids.txt
}

function add_job_no {
    if [[ "${JOB_NOS}" != "" ]]; then
        JOB_NOS="${JOB_NOS},"
    fi
    JOB_NOS="${JOB_NOS}${JOB_NO}"
}

setup

case ${WORK_ACTION} in
    index-bam)
        index-bam
        echo "job completed"
        ;;
    bam-stats)
        bam-stats
        echo "job completed"
        ;;
    bam-TO-goby_null)
        bam-TO-goby_null
        echo "job completed"
        ;;
    bam-TO-goby_gzip)
        bam-TO-goby_gzip
        echo "job completed"
        ;;
    goby_gzip-TO-goby_null)
        goby_gzip-TO-goby_null
        echo "job completed"
        ;;
    goby_any-TO-goby_cfs)
        goby_any-TO-goby_cfs
        echo "job completed"
        ;;
    goby_gzip-TO-goby_gzip)
        goby_gzip-TO-goby_gzip
        echo "job completed"
        ;;
    goby_gzip-TO-goby_gzip_perm)
        goby_gzip-TO-goby_gzip_perm
        echo "job completed"
        ;;
    goby_gzip-TO-goby_bzip2)
        goby_gzip-TO-goby_bzip2
        echo "job completed"
        ;;
    goby_gzip-TO-goby_bzip2_perm)
        goby_gzip-TO-goby_bzip2_perm
        echo "job completed"
        ;;
    goby_gzip-TO-goby_hybrid)
        goby_gzip-TO-goby_hybrid
        echo "job completed"
        ;;
    goby_gzip-TO-goby_hybrid_domain)
        goby_gzip-TO-goby_hybrid_domain
        echo "job completed"
        ;;
    goby_gzip-TO-goby_hybrid_perm)
        goby_gzip-TO-goby_hybrid_perm
        echo "job completed"
        ;;
    goby_gzip-TO-goby_hybrid_perm_no_templ)
        goby_gzip-TO-goby_hybrid_perm_no_templ
        echo "job completed"
        ;;
    goby_gzip-TO-bam)
        goby_gzip-TO-bam
        echo "job completed"
        ;;
    bam-TO-cram1)
        bam-TO-cram1
        echo "job completed"
        ;;
    bam-TO-cram2)
        bam-TO-cram2
        echo "job completed"
        ;;
    bam-TO-cram3)
        bam-TO-cram3
        echo "job completed"
        ;;
    cram1-TO-bam)
        cram1-TO-bam
        echo "job completed"
        ;;
    cram2-TO-bam)
        cram2-TO-bam
        echo "job completed"
        ;;
    cram3-TO-bam)
        cram3-TO-bam
        echo "job completed"
        ;;
    bam-TO-goby_hybrid_keep_max)
        bam-TO-goby_hybrid_keep_max 
        echo "job completed"
        ;;
    bam-TO-goby_hybrid_domain_noclips)
        bam-TO-goby_hybrid_domain_noclips
        echo "job completed"
        ;;
    goby_gzip-TO-goby_hybrid_no_templ)
        goby_gzip-TO-goby_hybrid_no_templ
        echo "job completed"
        ;;
    goby_hybrid_keep_max-TO-bam)
        goby_hybrid_keep_max-TO-bam
        echo "job completed"
        ;;
    goby_hybrid_domain-TO-bam)
        goby_hybrid_domain-TO-bam
        echo "job completed"
        ;;
    goby_gzip-TO-bam)
        goby_gzip-TO-bam
        echo "job completed"
        ;;
    bam-TO-bzip2_reads)
        bam-TO-bzip2_reads
        echo "job completed"
        ;;
    bam-TO-gzip_reads)
        bam-TO-gzip_reads
        echo "job completed"
        ;;
    bam-TO-bam_name_sort)
        bam-TO-bam_name_sort
        echo "job completed"
        ;;
    bam-TO-bam-comparison)
        bam-TO-bam-comparison
        echo "job completed"
        ;;
    bzip2_reads-TO-fastq_bzip2)
        bzip2_reads-TO-fastq_bzip2
        echo "job completed"
        ;;
    *)
        submit
        ;;
esac
copy_results
