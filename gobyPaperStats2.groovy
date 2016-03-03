#!/bin/env groovy
@Grab(group='com.martiansoftware', module='jsap', version='2.1')
@Grab(group='commons-lang', module='commons-lang', version='2.6')

import com.martiansoftware.jsap.IDMap
import com.martiansoftware.jsap.JSAP
import com.martiansoftware.jsap.JSAPResult
import com.martiansoftware.jsap.Parameter
import org.apache.commons.lang.StringUtils

class GobyPaperStats2 {

    final String XML_CONFIG = 
"""
<jsap>
    <parameters>
        <unflaggedOption>
            <id>input</id>
            <required>true</required>
            <greedy>true</greedy>
            <stringParser>
                <classname>StringStringParser</classname>
            </stringParser>
            <help>The SGE output log files to process.</help>
        </unflaggedOption>
        <flaggedOption>
            <id>reports-config-file</id>
            <shortFlag>c</shortFlag>
            <longFlag>reports-config-file</longFlag>
            <required>false</required>
            <stringParser>
                <classname>FileStringParser</classname>
            </stringParser>
            <defaults>
                <string>reportsConfig1.groovy</string>
            </defaults>
            <help>The reports config .groovy file to use to configure reporting. This name can define one or more reports to display. Look at the provided sample for the format.</help>
        </flaggedOption>
        <switch>
            <id>help</id>
            <shortFlag>h</shortFlag>
            <longFlag>help</longFlag>
            <help>Help</help>
        </switch>
        <switch>
            <id>tsv</id>
            <longFlag>tsv</longFlag>
            <help>TSV Ouptput Mode</help>
        </switch>
        <switch>
            <id>html</id>
            <longFlag>html</longFlag>
            <help>HTML Ouptput Mode</help>
        </switch>
        <switch>
            <id>average</id>
            <shortFlag>a</shortFlag>
            <longFlag>average</longFlag>
            <help>Create an averages row</help>
        </switch>
    </parameters>
</jsap>
"""

    def NORMAL_JOBS_PATTERN = ~/^([A-Z]+)-([a-z_123]+)-TO-([a-z_123]+).o(\d+)$/
    def CFS_JOBS_PATTERN = ~/^([A-Z]+)-([a-z_123]+)-TO-([a-z_123]+)-([a-z_123]+).o(\d+)$/

    def conversionFilesMap = [:]
    def allTags = new LinkedHashSet<String>();
    def tableIds = []

    def skipTags = ["YHEHSIL", "GGNEDKP"]

    def aligns = ["time":"right", "size":"right", "value":"right"]

    def tsvMode = false
    def htmlMode = false
    def urlPrefix = "http://gobywebdev.apps.campagnelab.org"

    def constsMap = [:]

    def inputFilenames
    def reportsConfig



    def bamDetailsMap = [
        "HZFWPTI" : [id:1, type:'Exome', filename:"NA12340.chrom11.ILLUMINA.bwa.CEU.exome.20111114.bam",
						size:576221831, sizeMapped: 572161646],
        "UANMNXR" : [id:2, type:'Exome', filename:"NA20766.chrom11.ILLUMINA.bwa.TSI.exome.20111114.bam",
						size:524874459, sizeMapped: 521935665],
        "MYHZZJH" : [id:3, type:'RNA-Seq', filename:"paper-combined-NA18853.bam",
						size:2997317402, sizeMapped: 2953233937],
        "ZHUUJKS" : [id:4, type:'RNA-Seq', filename:"paper-combined-NA19172.bam",
						size:1577064407, sizeMapped: 1537444442],
        "EJOYQAZ" : [id:5, type:'RNA-Seq', filename:"wgEncodeCaltechRnaSeqGm12878R2x75Il200SplicesRep1V2.bam",
						size:947585966, sizeMapped: 947585966],
        "JRODTYG" : [id:6, type:'RRBS', filename:"GSM675439_RRBS_rrbsmap_m12_r1.bam",
						size:1076355848, sizeMapped: 910903321],
        "ZVLRRJH" : [id:7, type:'Methyl-Seq', filename:"GSM721194_HCC1954.merged.2B.nodup.bam",
						size:1668773205, sizeMapped: 1668773205],
        "XAAOBVT" : [id:8, type:'WGS', filename:"SRA_HISEQ2000_FC1.bam",
						size:1502002628, sizeMapped: 1496454725],
        "UCCWRUX" : [id:9, type:'WGS', filename:"SRA_HISEQ2000_FC2.bam",
						size:1436235501, sizeMapped: 1405236914],
        "HENGLIT" : [id:10, type:'WGS', filename:"HengLi-30-SRR065390.bam",
						size:1766193610, sizeMapped: 1626110119],
    ]
    
    def translations = [
        "bzip2":                "goby_bzip2",
        "bzip2_perm":           "goby_bzip2_perm",
        "gzip":                 "goby_gzip",
        "gzip_perm":            "goby_gzip_perm",
	"hybrid":		"goby_hybrid",
        "hybrid_perm":          "goby_hybrid_perm",
        "hybrid_no_templ": 	"goby_hybrid_no_templ",
        "hybrid_perm_no_templ": "goby_hybrid_perm_no_templ",
        "goby_cfs":             "cfs",
	"hybrid_keep_max": 	"goby_hybrid_keep_max",
        "hybrid_domain": 	"goby_hybrid_domain"
    ]



    public static void main(String[] args) {
        new GobyPaperStats2().execute(args)
    }

    private void parseCommandLine(String[] args) {
        JSAPResult jsap = new JsapSupport()
            .setArgs(args)
            .setXmlConfig(XML_CONFIG)
            .setScriptName("gobyPaperStats2.groovy").parse()
        inputFilenames = jsap.getStringArray("input")
        htmlMode = jsap.getBoolean("html")
        tsvMode = jsap.getBoolean("tsv")
        def reportsConfigFile = jsap.getFile("reports-config-file")
        reportsConfig = new ConfigSlurper().parse(reportsConfigFile.toURL())
    }

    def execute(String[] args) {

        parseCommandLine(args)

        // Specify the order of the tags
        allTags << "HZFWPTI" << "UANMNXR" << "MYHZZJH" << "ZHUUJKS" << "EJOYQAZ" << "JRODTYG" << "ZVLRRJH" << "XAAOBVT" << "UCCWRUX"
      	// TODO sort input filenames by the order of the integer in the .o<integer> extension. This will rearrange 
      	// the files so that the most recent file is observed last.
       
        inputFilenames.each { String inputFilename ->
            observeFilename inputFilename
        }

        conversionFilesMap.each { k, v ->
            //try {
                    processFile(v)
            //} catch (Exception e) {
            //    System.err.println "Error processing ${v.filename}"
            //}
        }

        htmlHeader()
        if (reportsConfig.showToplevelReport) {
            printListOfMapsTabular("masterDetails",conversionFilesMap.values(), aligns)
        }
        runAllReports()
        htmlFooter()
    }
    
    def htmlHeader() {
        if (!htmlMode) {
            return
        }
        println """<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
            <html>
                <head>
                    <title>Goby Paper Details</title>
                    <link rel="stylesheet" type="text/css" href="${urlPrefix}/gobyweb/css/yui/yuireset.css" />
                    <link rel="stylesheet" type="text/css" href="${urlPrefix}/gobyweb/css/yui/yuifonts.css" />
                    <link rel="stylesheet" type="text/css" href="${urlPrefix}/gobyweb/css/setup.css" />
                    <link rel="stylesheet" type="text/css" href="${urlPrefix}/gobyweb/css/main.css" />
                    <style type="text/css">
                        td {font-family: Andale Mono, Courier New, Courier, Lucidatypewriter, Fixed, monospace}
                        td {white-space: nowrap}
                        .cellAlignleft {text-align: left; }
                        .cellAligncenter {text-align: center; }
                        .cellAlignright {text-align: right; }
                    </style>
                    <!-- jQuery CSS -->
                    <link rel="stylesheet" type="text/css" media="screen" href="${urlPrefix}/gobyweb/css/ui-custom-theme/jquery-ui-1.8.10.custom.css" />
                    <link rel="stylesheet" type="text/css" media="screen" href="${urlPrefix}/gobyweb/css/jquery/jquery.dataTables.1.9.0.css">
                    <script type="text/javascript" src="${urlPrefix}/gobyweb/js/jquery/jquery-1.7.1.min.js"></script>
                    <script type="text/javascript" src="${urlPrefix}/gobyweb/js/jquery/i18n/grid.locale-en.js"></script>
                    <script type="text/javascript" src="${urlPrefix}/gobyweb/js/jquery/jquery-ui-1.8.16.custom.min.js"></script>
                    <script type="text/javascript" src="${urlPrefix}/gobyweb/js/jquery/jquery.dataTables.dev.20120321.min.js"></script>
                </head>
                <body>
"""
    }
    
    def htmlFooter() {
        if (!htmlMode) {
            return
        }
        println """
            <script type="text/javascript">
            jQuery(document).ready(function() {
        """
        tableIds.each { tableId ->
            def scrollY = (tableId == "#masterDetails") ? /"sScrollY": 300,/ : ""
            println """
                        jQuery("${tableId}").dataTable({
                            "iDisplayLength": -1,
                            "aLengthMenu": [[-1], ["All"]],
                            ${scrollY} "sScrollX": 600,
                            "bPaginate": false,
                            "bJQueryUI": true,
                        });
            """
        }
        println """
                    });
                    </script>
                </body>
                </html>
        """
    }
    
    def observeFilename(filename) {
        def toAdd = null
        // fix filenames "/"s
        // println "Observing ${filename}"
        def shortFilename = filename.split("/")[-1]
        shortFilename.find(NORMAL_JOBS_PATTERN) { whole, tag, from, to, jobno ->
            toAdd = [:]
            toAdd["filename"] = filename
            toAdd["tag"] = tag
            toAdd["from"] = translate(from)
            toAdd["to"] = translate(to)
            toAdd["jobno"] = jobno as int
        }
        shortFilename.find(CFS_JOBS_PATTERN) { whole, tag, from, to, type, jobno ->
            toAdd = [:]
            toAdd["filename"] = filename
            toAdd["tag"] = tag
            toAdd["from"] = translate(type)
            toAdd["to"] = "cfs"
            toAdd["jobno"] = jobno as int
        }
        if (toAdd) {
            if (skipTags.contains(toAdd["tag"])) {
                return
            }
            allTags << toAdd["tag"]
            String key = toAdd["tag"] + "-" + toAdd["from"] + "-" + toAdd["to"]
            def prevAdd = conversionFilesMap[key]
            if (!prevAdd || (toAdd.jobno > prevAdd.jobno)) {
                if (prevAdd) {
                    System.err.println "Replacing ${prevAdd.filename} with ${toAdd.filename}"
                }
                conversionFilesMap[key] = toAdd
            }
        }
    }

    def translate(from) {
        translations[from] ?: from
    }


    def executeEquation(tag, comparisonMap) {
        def values = [:]
        def constants = [:]
        boolean allFound = true
        def variables = new LinkedHashSet<String>()
        comparisonMap.each { key, value ->
            if (key.endsWith("From")) {
                variables << (key - "From")
            } else if (key.endsWith("To")) {
                variables << (key - "To")
            }
        }
        variables.each { variable ->
            def key = tag + "-" + comparisonMap["${variable}From"] + "-" + comparisonMap["${variable}To"]
            def found = conversionFilesMap[key]
            if (found) {
                values[variable] = found
            } else {
                allFound = false
            }
        }
        if (!allFound) {
            return  ""
        }
        
        Binding binding = new Binding();
        values.each { variable, value ->
            binding.setVariable(variable, value);
        }
        constants.each { constant, value ->
            binding.setVariable(constant, value);
        }

        binding.setVariable("constsMap", constsMap);
        binding.setVariable("bamDetailsMap", bamDetailsMap);
        binding.setVariable("tag", tag);

        GroovyShell shell = new GroovyShell(binding);
        def result
        try {
            /*
            println "tag=${tag}"
            println "bamDetailsMap=${bamDetailsMap}"
            println "constsMap=${constsMap}"
            println "constsMap=${comparisonMap}"
            */
            result = shell.evaluate(comparisonMap.equation);
        } catch (ArithmeticException e) {
            return e.getMessage()
        } catch (NullPointerException e) {
	    return e.getMessage() 
        } 


        if (comparisonMap["outputFormat"]) {
          try{            
             return String.format(comparisonMap.outputFormat, result)
	  } catch (IllegalArgumentException e) {
		print "invalid format:"+comparisonMap.outputFormat        
          }

        } else {
            return result
        }
    }

    def runAllReports() {
        reportsConfig.reports.each { String reportName, Map reportDetails ->
            if (!reportDetails.visible) {
                return
            }
            def allData = [:]
            if (htmlMode) {
                println "<p>&nbsp;</p>"
            } else {
                println ""
            }
            reportDetails.columns.each { Map reportItem ->
                allTags.each { tag ->
                    def tagRow = allData[tag]
                    if (!tagRow) {
                        tagRow = [:]
                        tagRow.tag = tag
                        allData[tag] = tagRow
                    }
                    tagRow[reportItem.description] = executeEquation(tag, reportItem)
                    aligns[reportItem.description] = reportItem.align ?: "right"
                }
            }
            printListOfMapsTabular(reportName, allData.values(), aligns)
        }
    }

    /**
     * This will print a List of Map<String, String> in an easy to read tabular fashion.
     * @param rowMaps the list of rows to print. Ideally, each map has the same fields, but that doesn't really matter.
     * @param aligns a map of columnName to alignment. Default alignment is left. Also accepted is "right".
     */
    def printListOfMapsTabular(String tableId, rowMaps, aligns) {
        tableIds << "#${tableId}"
        def columnNamesToSizes = [:]
        rowMaps.each { rowMap ->
            rowMap.each { columnName, columnValueAny ->
                String columnValue = "${columnValueAny}"
                columnNamesToSizes[columnName] = Math.max(columnValue?.size() ?: 0,  columnNamesToSizes[columnName] ?: columnName.size())
            }
        }
        outputHeader(tableId, columnNamesToSizes)
        if (htmlMode) {
            println "<tbody>"
        }
        rowMaps.each { rowMap ->
            if (htmlMode) {
                println "<tr>"
            }
            int colNo = 0
            columnNamesToSizes.each { columnName, columnSize ->
                cellPrint(false, colNo++, rowMap[columnName] ?: "", columnSize, aligns[columnName] ?: "left")
            }
            println ""
            if (htmlMode) {
                println "</tr>"
            }
        }
        if (htmlMode) {
            println "</tbody>"
            println "</table>"
        }
    }

    class ColHeader {
        def major
        def minors = []
        boolean discard = false
        public ColHeader(columnName) {
            def (prefix, suffix) = (columnName.split(",", 2) as List).collect { it.trim() }
            major = prefix
            if (suffix) {
                minors << suffix
            }
        }
    }
    
    public List<ColHeader> defineHeaders(columnNamesToSizes) {
        def headers = []
        int numMinors = 0
        columnNamesToSizes.each { columnName, columnSize ->
            def header = new ColHeader(columnName)
            numMinors += header.minors.size()
            headers << header
        }
        def prevHeader = null
        def discardHeaders = []
        headers.each { ColHeader header ->
            if (prevHeader) {
                if (prevHeader.major == header.major) {
                    prevHeader.minors.addAll header.minors
                    discardHeaders << header
                } else {
                    prevHeader = header
                }
            } else {
                prevHeader = header
            }
        }
        discardHeaders.each { ColHeader header ->
            headers.remove header
        }
        return [headers, numMinors > 0]
    }
    

    def outputHeader(tableId, columnNamesToSizes) {
        def (headers, hasMinors) = defineHeaders(columnNamesToSizes)
        if (htmlMode) {
            println "<table id='${tableId}'>"
            println "<thead>"
            println "<tr>"
            headers.each { ColHeader header ->
                int numMinors = header.minors.size()
                if (numMinors == 0) {
                    def rowSpan = ""
                    if (hasMinors) {
                        rowSpan = "rowspan='2'"
                    }
                    println "<th ${rowSpan}>${header.major}</th>"
                } else {
                    def colSpan = ""
                    if (headers.minors.size() > 1) {
                        colSpan = "colspan='${header.minors.size()}'"
                    }
                    println "<th ${colSpan}>${header.major}</th>"
                }
            }
            println "</tr>"
            if (hasMinors) {
                println "<tr>"
                headers.each { ColHeader header ->
                    int numMinors = header.minors.size()
                    if (numMinors > 0) {
                        header.minors.each { minor ->
                            println "<th>${minor}</th>"
                        }
                    }
                }
                println "</tr>"
            }
            println "</thead>"
        } else {
            int colNo = 0
            columnNamesToSizes.each { columnName, columnSize ->
                cellPrint(true, colNo++, columnName, columnSize, "center")
            }
            println ""

            if (!tsvMode) {
                colNo = 0
                columnNamesToSizes.each { columnName, columnSize ->
                    cellPrint(false, colNo++, "-" * columnSize, columnSize, "left")
                }
                println ""
            }
        }
    }
    
    def cellPrint(boolean headerCell, int colNo, valueAny, size, alignment="left") {
        String value = "${valueAny}"
        int leftSpaces = 0
        int rightSpaces = 0
        if (!tsvMode && !htmlMode) {
            if (alignment == "center") {
                int allSpaces = Math.max(size - value.size(), 0) 
                leftSpaces = (int) (allSpaces / 2)
                rightSpaces = allSpaces - leftSpaces
            } else if (alignment == "right") {
                leftSpaces = Math.max(size - value.size(), 0) 
                rightSpaces = 0
            } else {
                leftSpaces = 0
                rightSpaces = Math.max(size - value.size(), 0) 
            }
        }
        if (colNo > 0) {
            if (tsvMode) {
                print "\t"
            } else {
                print "  "
            }
        }
        if (htmlMode) {
            print "<td class='cellAlign${alignment}'>"
        } else if (tsvMode) {
        } else {
            if (leftSpaces > 0) {
                print " " * leftSpaces
            }
        }
        if (htmlMode) {
            if (alignment == "right" && value.isLong()) {
                printf("%,d", value as long)
            } else {
                print value
            }
        } else {
            print value
        }
        if (htmlMode) {
            print "</td>"
        } else if (tsvMode) {
        } else {
            if (rightSpaces > 0) {
                print " " * rightSpaces
            }
        }
    }
    
    def processFile(fileMap) {
        int time
        long size
        double bitsPerBase
        boolean nextLineIsSize = false
        boolean nextLineIsBitsPerBase = false
        boolean failed = false
        boolean inStats = false
        new File(fileMap.filename).eachLine { String line ->
            if (line.contains("Exception") && !inStats) {
                failed = true
            }
            if (line.startsWith("real\t")) {
                time = timeToSeconds(line)
            }
            if (line == ":compact alignment sizes") {
                nextLineIsSize = true
                nextLineIsBitsPerBase = false
                return
            }
            if (line == ". Statistics") {
                inStats = true
            }
            if (line == ":bits per base") {
                nextLineIsBitsPerBase = true
                nextLineIsSize = false
                return
            }
            if (nextLineIsSize) {
                nextLineIsSize = false
                def parts = line.split("=")
                try {
                    size = parts[1].trim() as long
                } catch (Exception e) {
                    size= -1
                }

            }
            if (nextLineIsBitsPerBase) {
                nextLineIsBitsPerBase = false
                def parts = line.split(":")
                try {
                    bitsPerBase = parts[1].trim() as double
                } catch (Exception e) {
                    bitsPerBase = -1
                }
            }
    
        }
        fileMap.time = time
        fileMap.size = size
        fileMap.bpb = bitsPerBase
        if (failed) {
            fileMap.failed = true
        }
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
}

/**
 * This is a support class used by other Groovy scripts in this directory.
 * The purpose of this script is provide JSAP so the calling class
 * can providate JSAP XML configuration and this class will assist with
 * command line parsing.
 */ 
public class JsapSupport {

    private String scriptName
    private String[] args
    private String xmlConfig
    private Map<String, String> helpValues
    private boolean exitOnFailureOrHelp
    private int failureExitCode
    private int helpExitCode

    private boolean failure
    private boolean help

    public JsapSupport() {
        reset()
    }

    public JsapSupport reset() {
        scriptName = "?scriptName?.groovy"
        args = new String[0]
        xmlConfig = ""
        helpValues = null
        exitOnFailureOrHelp = true
        failure = false
        help = false
        failureExitCode = 1
        helpExitCode = 0
        return this
    }
    
    public JsapSupport setScriptName(final String scriptName) {
        this.scriptName = scriptName
        return this
    }

    public String getScriptName() {
        return this.scriptName
    }

    public JsapSupport setArgs(final String[] args) {
        this.args = args
        return this
    }

    public String[] getArgs() {
        return this.args
    }

    public JsapSupport setXmlConfig(final String xmlConfig) {
        this.xmlConfig = xmlConfig
        return this
    }

    public String getXmlConfig() {
        return this.xmlConfig
    }

    public JsapSupport setHelpValues(final Map<String, String> helpValues) {
        this.helpValues = helpValues
        return this
    }

    public Map<String, String> getHelpValues() {
        return this.xmlConfig
    }

    public JsapSupport setExitOnFailureOrHelp(final boolean exitOnFailure) {
        this.exitOnFailureOrHelp = exitOnFailureOrHelp
        return this
    }

    public boolean getExitOnFailureOrHelp() {
        return this.exitOnFailureOrHelp
    }

    public JsapSupport setFailureExitCode(final int failureExitCode) {
        this.failureExitCode = failureExitCode
        return this
    }

    public int getFailureExitCode() {
        return this.failureExitCode
    }

    public JsapSupport setHelpExitCode(final int helpExitCode) {
        this.helpExitCode = helpExitCode
        return this
    }

    public int getHelpExitCode() {
        return this.helpExitCode
    }
    
    public JSAPResult parse() {
        File xmlConfigFile
        JSAP jsap
        try {
            xmlConfigFile = File.createTempFile("jsap", ".xml")
            xmlConfigFile.write xmlConfig
            final URL xmlConfigUrl = xmlConfigFile.toURL()
            jsap = new JSAP(xmlConfigUrl)
            processHelpValues(jsap, helpValues)
        } catch (NullPointerException e) {
            System.err.println "Warning! jsap XML configuration file ${xmlConfigFile} not found"
            jsap = new JSAP()
        } finally {
            if (xmlConfigFile && xmlConfigFile.exists()) {
                xmlConfigFile.delete()
            }
        }
        final JSAPResult jsapResult = parseJsap(jsap)
        if (!help) {
            abortOnError(jsap, jsapResult)
        }
        if (failure || help) {
            if (exitOnFailureOrHelp) {
                if (help) {
                    System.exit(helpExitCode)
                }
                if (failure) {
                    System.exit(failureExitCode)
                }
            }
            return null
        } else {
            return jsapResult
        }
    }

    private void processHelpValues(final JSAP jsap,  final Map<String, String> helpValues) {
        if (!helpValues) {
            return
        }
        final IDMap idMap = jsap.getIDMap()
        final Iterator<String> idIterator = idMap.idIterator()
        while (idIterator.hasNext()) {
            final String id = idIterator.next()
            final Parameter param = jsap.getByID(id)
            final String help = param.getHelp()
            final String[] defaults = param.getDefault()
            for (final Map.Entry<String, String> entry : helpValues.entrySet()) {
                // replace values in help
                if (help.contains(entry.getKey())) {
                    param.setHelp(StringUtils.replace(help, entry.getKey(), entry.getValue()))
                }
                // replace values in defaults
                if (defaults != null) {
                    for (int i = 0; i < defaults.length; i++) {
                        if (defaults[i].contains(entry.getKey())) {
                            defaults[i] = StringUtils.replace(
                                    defaults[i], entry.getKey(), entry.getValue())
                        }
                    }
                }
            }
        }
    }

    private JSAPResult parseJsap(final JSAP jsap) {
        final JSAPResult jsapResult = jsap.parse(args)
        if (jsap.getByID("help") != null && jsapResult.getBoolean("help")) {
            printUsage(jsap)
            help = true
        }
        return jsapResult
    }

    private void abortOnError(final JSAP jsap, final JSAPResult jsapResult) {
        if (!jsapResult.success()) {
            System.err.println()
            for (final Iterator errs = jsapResult.getErrorMessageIterator(); errs.hasNext();) {
                System.err.println("Error: " + errs.next())
            }
            System.err.println()
            printUsage(jsap)
            failure = true
        }
    }

    public void printUsage(final JSAP jsap) {
        System.err.println("Usage:")
        System.err.println("groovy ${scriptName} ${jsap.getUsage()}")
        System.err.println("")
        System.err.println(jsap.getHelp(JSAP.DEFAULT_SCREENWIDTH - 1))
    }
}
