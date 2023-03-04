import httpClient
import strutils
import sequtils
import times
import sugar
import os

const 
  defaultDataSetsCfgFile = "datasets.txt"
  defaultDataSetsCfg = [
    ("https://psl.noaa.gov/data/correlation/amon.us.long.mean.data",
    "amocol.txt","amomatrix.txt","AMO"),
    ("https://psl.noaa.gov/gcos_wgsp/Timeseries/Data/nino34.long.data",
    "ninocol.txt","ninomatrix.txt","NINA34")
  ]

type 
  DataSet = tuple[url,colFile,matrixFile,id:string]
  DataPoint = tuple[year:int,month:Month,value,anom:float]
  MeanData = tuple[accum:float,count:int]
 
func generateDataPoints(years:seq[int],values:seq[float]):seq[DataPoint] =
  var idx = 0
  for year in years:
    for month in Month:
      result.add (year,month,values[idx],0.0)
      if idx < values.high: inc idx else: return

func parseMonthlyMeansData(dataPoints:seq[DataPoint]):array[Month,MeanData] =
  for datapoint in datapoints:
    result[datapoint.month].accum += datapoint.value
    result[datapoint.month].count += 1

func calcAnoms(dataPoints:seq[DataPoint]):seq[DataPoint] =
  let monthlyMeansData = dataPoints.parseMonthlyMeansData
  for dataPoint in dataPoints:
    result.add dataPoint
    result[^1].anom = dataPoint.value-(
      monthlyMeansData[dataPoint.month].accum/
      monthlyMeansData[dataPoint.month].count.toFloat
    )

func parseDataItems(data,id:string):seq[string] =
  let dataItems = data.splitWhitespace
  for dataItem in dataItems[2..<dataItems.find(id)]:
    if dataItem[0] != '-': result.add dataItem

func parseYearsAndValues(dataItems:seq[string]):(seq[int],seq[float]) =
  for idx,dataItem in dataItems:
    if idx == 0 or idx mod 13 == 0:
      result[0].add dataItem.parseInt else:
      result[1].add dataItem.parseFloat

func parseData(data,id:string): (seq[DataPoint],seq[int]) =
  let (years,values) = data.parseDataItems(id).parseYearsAndValues
  (generateDataPoints(years,values).calcAnoms,years)

func columnFormat(dataPoints:seq[DataPoint]):seq[string] = collect: 
  for dataPoint in dataPoints:
    ($dataPoint.month)[0..2]&" "&($dataPoint.year)&
    ($dataPoint.anom)[0..5].indent(4)
  
func matrixFormat(dataPoints:seq[DataPoint],years:seq[int]):seq[string] =
  var idx = 0
  result.add chr(32).repeat(4).join&Month.mapIt(($it)[0..2].align(9)).join
  for year in years:
    var line = $year
    for month in Month:
      let anom = dataPoints[idx].anom
      line = line&($anom)[0..(if anom < 0: 6 else: 5)].align(9)
      if idx == dataPoints.high: break
      inc idx
    result.add line
  result.add '-'.repeat(result[^2].len).join

func parseDataSetsCfg(setLines:seq[string]):seq[DataSet] =
  var lines:seq[string]
  for line in setLines:
    lines.add line
    if lines.len == 4: 
      result.add (lines[0],lines[1],lines[2],lines[3])
      lines.setLen(0)

proc output(processedDataSet:(string,seq[string])) =
  let (path,lines) = processedDataSet
  var txtFile = open(path,fmWrite)
  defer: close(txtFile)
  for line in lines: 
    txtFile.writeLine(line)
    echo line

proc processDataSet(dataSet:DataSet):array[2,(string,seq[string])] =
  let (datapoints,years) = newHttpClient().getContent(dataSet.url).parseData(dataSet.id)
  result = [
    (dataSet.colFile,dataPoints.columnFormat),
    (dataSet.matrixFile,dataPoints.matrixFormat(years))
  ]  

proc readDataSets(path:string):seq[DataSet] =
  var setLines:seq[string]
  try:
    setLines = collect:
      for line in lines(path): line
    if setLines.len mod 4 != 0:
      let errorMsg = "Invalid number of lines, reading file: "&path
      raise newException(CatchableError, errorMsg)
  except: 
    echo getCurrentExceptionMsg()
    echo "Using default dataSets"
    return @defaultDataSetsCfg
  setLines.parseDataSetsCfg

proc cfgFile():string =
  let msg = "Reading dataset configuration from file: "
  if paramCount() == 1 and fileExists(paramStr(1).strip):
    echo msg,paramStr(1)
    return paramStr(1)
  else:
    echo msg,defaultDataSetsCfgFile
    return defaultDataSetsCfgFile

for dataSet in cfgFile().readDataSets:
  for processedDataSet in dataSet.processDataSet: 
    output(processedDataSet)
