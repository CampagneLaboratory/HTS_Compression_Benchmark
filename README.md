# Overview
This repository contains the benchmark scripts for the high-throughput sequencing data compression benchmark described in (Campagne et al 2013 PLOS One)[http://journals.plos.org/plosone/article?id=10.1371/journal.pone.0079871].
Data necessary for the benchmark are distributed at http://data.campagnelab.org/home/compression-of-structured-high-throughput-sequencing-data.

# Requirements
In order to run this benchmark, you need access to a cluster with Sun Grid Engine installed and a number of programs already installed. Key requirements are Java, Groovy and samtools. The benchmark was developed in 2012 and is mostly maintained so that it keeps running.

# How to run the benchmark

1. You will need to download the data and configure the submit.sh to point to its location on your cluster
2. After this, select which alignments you need to evaluate by editing the line TAGS=“”. This variable should contain a space separated list of TAGS for the alignments used in the benchmark.
3. In submit.sh, locate the lines that set WORK_ACTIONS (look for WORK_ACTIONS=) and uncomment one line at a time, then run submit.sh to submit these work items to the queue. Start by uncommenting the line marked with #1, save the file, run submit.sh. You can continue as soon as submission is finished. The script submit.sh will add dependencies on previous jobs using the last_jobs_pids.txt file. A complete benchmark has 7 steps. 