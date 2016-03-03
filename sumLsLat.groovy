#!/bin/env groovy


def sumLines = []
System.in.eachLine { String line ->
    sumLines << line
}
sum(sumLines)


def sum(lines) {
    def sum = 0
    def lsPattern = ~/^[rwxd-]+\s+\d+\s+\w+\s+\w+\s+(\d+)\s+\w+\s+\d+\s+\d+:\d+\s+(.*)$/
    def foundTags = new HashSet<String>()
    def foundTypes = new HashSet<String>()
    Map<String, List<Long>> tagToLengthsMap = [:]
    def keepExts = ["index", "header", "entries", "cram","crai","ngc", "bam", "compact-reads", "1_fq_gz", "2_fq_gz", "1_fq_bz2", "2_fq_bz2"]
    lines.each { String line ->
        if (!line) {
            return
        }
        def match = false
        line.find(lsPattern) { String whole, String length, String wholeFilename ->
            // Filename may be a path, remove any directory elements
            def filenameParts = wholeFilename.split("/")
            filename = filenameParts[-1]
            filenameParts = filename.split("[\\.]") as List
            if (filenameParts.size() <= 1) {
                // Filename may be ., .. or otherwise not have an extension, we don't want it
                System.err.println "Skipping ${filename} because it has no extension"
                return
            }
            // Rove the file extension, then reconstruct if there were more than one "." in the filename
            def fileExt = filenameParts[-1]
            if (!keepExts.contains(fileExt)) {
                System.err.println "Skipping ${filename} beause of it's file extension '${fileExt}'"
                return
            }
            filenameParts.remove(filenameParts.size() - 1)
            def filenameNoExt = filenameParts.join(".")
            // Retrieve the tag "-" filetype
            filenameParts = filenameNoExt.split("-", 2) as List
            if (filenameParts.size() != 2) {
                // We didn't see tag + "-" + type. we don't want it
                if (filenameParts.size() == 1 && filenameParts[0].size() == 7 && filenameParts[0].toUpperCase() == filenameParts[0]) {
                    filenameParts << "(no-type)"
                } else {
                    System.err.println "Skipping ${filename} because it doesn't have a tag"
                    return
                }
            }
            tag = filenameParts[0]
            type = filenameParts[1]
            long currentLength = (length as long)
            String key = "${tag}-${type}"

            def lengthsPerTag = tagToLengthsMap[key]
            if (lengthsPerTag == null) {
                lengthsPerTag = []
                tagToLengthsMap[key] = lengthsPerTag
            }

            lengthsPerTag << currentLength
            match = true
        }
    }
    System.err.println ""
    tagToLengthsMap.each { String tag, List<Long> toSum ->
        println "${tag}  total size (${toSum.join('+')}) = ${toSum.sum()}"
    }
    return null
}
