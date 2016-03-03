#!/bin/env groovy
def startedParsing = false
List<Job> jobs = []
Job currentJob = null
System.in.eachLine { String line ->
    List<String> parts = line.split("[ ]+", 10) as List
    parts.remove(0)
    if (parts.size() == 0) {
        return
    }
    def newSection = false
    if (parts[0].isNumber()) {
        startedParsing = true
        newSection = true
    }
    if (!startedParsing) {
        return
    }
    parts = parts.collect { it.trim() }
    if (newSection) {
        currentJob = new Job()
        currentJob.id = parts[0] as int
        jobs << currentJob
        currentJob.priority = parts[1] as double
        currentJob.shortName = parts[2]
        currentJob.user = parts[3]
        currentJob.state = parts[4]
        currentJob.submitStartDate = parts[5]
        currentJob.submitStartTime = parts[6]
        currentJob.queue = parts[7]
        currentJob.slots = parts[8]
        currentJob.details = new LinkedHashMap<String, String>()
        
        // Special parsing case for array jobs
        if (!currentJob.queue.contains("@")) {
            currentJob.slots = currentJob.queue + " " + currentJob.slots
            currentJob.queue = " "
        }
    } else {
        parts = line.split(":", 2) as List
        parts = parts.collect { it.trim() }
        if (parts.size() == 2) {
            currentJob.lastDetailsKey = parts[0]
            if (parts[1]) {
                if (currentJob.lastDetailsKey == "Full jobname") {
                    currentJob.fullName = parts[1] 
                } else {
                    currentJob.details[currentJob.lastDetailsKey] = parts[1]
                }
            }
        } else {
            if (parts[0]) {
                currentJob.details[currentJob.lastDetailsKey] = parts[0]
            }
        }
    }
}
println """
<html>
<head>
  <link rel="stylesheet" type="text/css" href="http://yui.yahooapis.com/3.3.0/build/cssreset/reset-min.css"/>
  <style TYPE="text/css"> 
      th {font-size:80%; font-weight: bold;} 
      td {font-size:80%}
  </style> 
  <script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js"></script>
  <script type="text/javascript" src="http://cdn.ucb.org.br/Scripts/tablesorter/jquery.tablesorter.min.js"></script>
  <script type="text/javascript">
    jQuery(document).ready(function() {
      jQuery("#data").tablesorter();
    });
  </script>
</head>
<body>
<table border='1' id="data">
<thead>
"""
println Job.htmlHeaderRow()
println "</thead><tbody>"
jobs.each { j ->
    println j.toHtmlRow()
}
println "</tbody>"
println "</table>"
println "</body>"
println "</html>"

class Job {
    int id
    double priority
    String fullName
    String shortName
    String user
    String state
    String submitStartDate
    String submitStartTime
    String queue
    String slots
    Map<String, String> details
    String lastDetailsKey
    public String toString() {
        String job = "id=${id}  fullName=${fullName}\n" +
            "   user=${user}\n" +
            "   priority=${priority}\n" +
            "   state=${state}\n" +
            "   submit/start date=${submitStartDate} ${submitStartTime}\n" +
            "   queue=${queue}\n" +
            "   slots=${slots}\n" +
            "   details="
        details.each { k, v ->
            job += "\n      ${k}=${v}"
        }
        return job
    }
    public static String htmlHeaderRow() {
        String row = "<tr>"
        row += "<th>id</th>"
        row += "<th>fullName</th>"
        row += "<th>user</th>"
        row += "<th>priority</th>"
        row += "<th>state</th>"
        row += "<th>submit/start date</th>"
        row += "<th>queue</th>"
        row += "<th>slots</th>"
        row += "<th>details</th>"
        row += "</tr>"
    }
    public String toHtmlRow() {
        String job = "<tr>"
        job += "<td>${id}</td>"
        job += "<td>${fullName}</td>"
        job += "<td>${user}</td>"
        job += "<td>${priority}</td>"
        job += "<td>${state}</td>"
        job += "<td>${submitStartDate} ${submitStartTime}</td>"
        job += "<td>${queue}</td>"
        job += "<td>${slots}</td>"
        job += "<td>"
        details.each { k, v ->
            job += "${k}=${v}<br/>"
        }
        job += "</td>"
        job += "</tr>"
    }
}
