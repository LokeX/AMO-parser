import httpClient
import strutils
import sequtils
import times
import math

type 
  DataPoint = tuple
    year:int
    month:Month
    value,anom:float
 
func strToFloat(s:string):float = 
  try:s.parseFloat except:0

func strToInt(s:string):int = 
  try:s.parseInt except:0

func parseDataItems(data:string):seq[string] =
  let
    dataItems = data.splitWhitespace
    startIdx = 2
    endIdx = dataItems.find("AMO")-1
  toSeq(startIdx..endIdx).mapIt(dataItems[it]).filterIt(it[0] != '-')

func calcMonthlyMeans(dataPoints:seq[DataPoint]):seq[float] =
  for month in Month:
    let monthlyValues = dataPoints.filterIt(it.month == month).mapIt(it.value)
    result.add monthlyValues.sum/monthlyValues.len.toFloat

func generateDataPoints(years:seq[int],values:seq[float]):seq[DataPoint] =
  var idx = 0
  for year in years:
    for month in Month:
      result.add (year,month,values[idx],0.0)
      if idx < values.len-1:inc idx else:return

func calcAnoms(dataPoints:seq[DataPoint]):seq[DataPoint] =
  let monthlyMeans = dataPoints.calcMonthlyMeans
  result = dataPoints
  for i,dataPoint in dataPoints:
    result[i].anom = dataPoint.value-monthlyMeans[dataPoint.month.ord-1]

func parseYearsAndValues(dataItems:seq[string]): (seq[int],seq[float]) =
  var 
    years:seq[int]
    values:seq[float]
  for count,dataItem in dataItems:
    if count == 0 or count mod 13 == 0:
      years.add dataItem.strToInt
    else:
      values.add dataItem.strToFloat
  (years,values)

func parseData(data:string):(seq[DataPoint],seq[int]) =
  let
    (years,values) = data.parseDataItems.parseYearsAndValues
    dataPoints = generateDataPoints(years,values).calcAnoms
  (dataPoints,years)

func anomsColFormat(dataPoints:seq[DataPoint]):seq[string] =
  for dataPoint in dataPoints:
    let
      month = $dataPoint.month
      year = $dataPoint.year
      date = month[0..2]&" "&year
      anom = $dataPoint.anom
    result.add date&anom[0..5].indent(4)

func anomsMatrixFormat(dataPoints:seq[DataPoint],years:seq[int]):seq[string] =
  var idx = 0
  result.add " ".cycle(4).join&Month.mapIt($it).mapIt(it[0..2].align(9)).join
  for year in years:
    var line = $year
    for month in Month:
      let anom = $dataPoints[idx].anom
      line = line&anom[0..(if dataPoints[idx].anom < 0:6 else:5)].align(9)
      if idx == dataPoints.len-1: break
      inc idx
    result.add line
  result.add "-".cycle(result[^2].len).join

proc writeFile(path:string,lines:seq[string]) =
  var txtFile = open(path,fmWrite)
  defer: close(txtFile)
  for line in lines: txtFile.writeLine(line)

proc echoFile(path:string) =
  for line in lines(path):echo line
  echo "File: ",path

proc output(path:string,lines:seq[string]) =
  writeFile(path,lines)
  echoFile(path)

const
  fileNameCol = "anomscol.txt"
  fileNameMatrix = "anomsmatrix.txt"
  url = "https://psl.noaa.gov/data/correlation/amon.us.long.mean.data"

let (datapoints,years) = newHttpClient().getContent(url).parseData
output(fileNameCol,dataPoints.anomsColFormat)
output(fileNameMatrix,dataPoints.anomsMatrixFormat(years))
