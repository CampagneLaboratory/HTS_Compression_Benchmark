#!/bin/env groovy

args.each { String fileToProcess ->
    if (new File(fileToProcess).exists()) {
	    processFile(fileToProcess)
	} else {
	    println "Could not process file: ${fileToProcess}"
	}
}

def processFile(filename) {
	String bitsPerBase = "unknown"
	new File(filename).eachLine { String line ->
		if (line.startsWith("Average bits per read base")) {
			def parts = line.split("=", 2)
			bitsPerBase = parts[1].trim()
		}
	}
	println "${filename} : ${bitsPerBase}"
}

def timeToSeconds(String timeHms) {
    if (!timeHms.trim()) {
        return timeHms
    }
    def timeMap = [:]

    def matched = false
	timeHms.find(~/^real\W+(\d+)m(\d+)[.](\d+)s$/) { whole, m, s, ms ->
        matched = true
        timeMap["h"] = 0
        timeMap["m"] = m as int
        timeMap["s"] = s as int
        if ((ms as int) >= 500) {
            timeMap["s"] += 1
        }
    }
    if (!matched) {
		timeHms.find(~/^(\d+):(\d+):(\d+)$/) { whole, h, m, s ->    
			matched = true
			timeMap["h"] = h as int
			timeMap["m"] = m as int
			timeMap["s"] = s as int
		}
	}
	if (!matched) {
		return timeHms
	}
    if (timeMap["h"] > 0) {
        timeMap["m"] += timeMap["h"] * 60
    } 
    if (timeMap["m"] > 0) {
        timeMap["s"] += timeMap["m"] * 60
    }
    timeMap.remove("h")
    timeMap.remove("m")
	return timeMap["s"]
}
