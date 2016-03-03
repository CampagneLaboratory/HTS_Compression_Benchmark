crashowToplevelReport = true

reports["BamComparisons"] = [
    visible : true,
    columns : [
        [description:   "id",
         equation:      "bamDetailsMap[tag].id",
         align:         "left",
        ],
        [description:   "type",
         equation:      "bamDetailsMap[tag].type",
         align:         "left",
        ],
        /*
        [description:   "Cram1 / BAM",
         aFrom:         "bam",
         aTo:           "cram1",
         equation:      "(a.size / bamDetailsMap[tag].sizeMapped) * 100",
         outputFormat:  "%.02f%%",
        ],
        [description:   "Cram2 / BAM",
         aFrom:         "bam",
         aTo:           "cram2",
         equation:      "(a.size / bamDetailsMap[tag].sizeMapped) * 100",
         outputFormat:  "%.02f%%",
        ],
        */
        [description:   "H+T+D>BAM / BAM",
         aFrom:         "goby_hybrid_domain",
         aTo:           "bam",
         equation:      "(a.size / bamDetailsMap[tag].sizeMapped) * 100",
         outputFormat:  "%.02f%%",
        ],
        [description:   "Cram1>BAM / BAM",
         aFrom:         "cram1",
         aTo:           "bam",
         equation:      "(a.size / bamDetailsMap[tag].sizeMapped) * 100",
         outputFormat:  "%.02f%%",
        ],
        [description:   "Cram2>BAM / BAM",
         aFrom:         "cram2",
         aTo:           "bam",
         equation:      "(a.size / bamDetailsMap[tag].sizeMapped) * 100",
         outputFormat:  "%.02f%%",
        ],
        /*
        [description:   "Cram3 / BAM",
         aFrom:         "bam",
         aTo:           "cram3",
         equation:      "(a.size / bamDetailsMap[tag].sizeMapped) * 100",
         outputFormat:  "%.02f%%",
        ],
        */
        [description:   "H+T+Q>BAM / BAM",
         aFrom:         "goby_hybrid_keep_max",
         aTo:           "bam",
         equation:      "(a.size / bamDetailsMap[tag].sizeMapped) * 100",
         outputFormat:  "%.02f%%",
        ],
        [description:   "Cram3>BAM / BAM",
         aFrom:         "cram3",
         aTo:           "bam",
         equation:      "(a.size / bamDetailsMap[tag].sizeMapped) * 100",
         outputFormat:  "%.02f%%",
        ],
        [description:   "H+T+D>BAM / BAM",
         aFrom:         "goby_hybrid_domain",
         aTo:           "bam",
         equation:      "(a.size / bamDetailsMap[tag].sizeMapped) * 100",
         outputFormat:  "%.02f%%",
        ],
        [description:   "gzip>bam / BAM",
         aFrom:         "goby_gzip",
         aTo:           "bam",
         equation:      "(a.size / bamDetailsMap[tag].sizeMapped) * 100",
         outputFormat:  "%.02f%%",
        ],
     
      
    ]
]
