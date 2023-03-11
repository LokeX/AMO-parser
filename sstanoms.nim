from times import Month
from httpClient import newHttpClient,getContent
from os import fileExists,commandLineParams
from sequtils import mapIt,toSeq
from sugar import collect
import strutils

const 
  formats = ["column","matrix"]
  defaultDataSetsCfgFile = "datasets.txt"
  defaultDataSetsCfg = [
    ("AMO","https://psl.noaa.gov/data/correlation/amon.us.long.mean.data"),
    ("NINA34","https://psl.noaa.gov/gcos_wgsp/Timeseries/Data/nino34.long.data")
  ]

type 
  DataSet = tuple[id,url:string]
  DataPoint = tuple[year:int,month:Month,value,anom:float]
  MeanData = tuple[accum:float,count:int]
 
func dataSetLines(dataSet:DataSet):string = 
  for line in dataSet.fields: result.add line&"\n"

func defaultDataSetsCfgLines():string = 
  defaultDataSetsCfg.mapIt(it.dataSetLines).join

func generateDataPoints(years:seq[int],values:seq[float]):seq[DataPoint] =
  var idx = 0
  for year in years:
    for month in Month:
      result.add (year,month,values[idx],0.0)
      if idx < values.high: inc idx else: return

func calcMonthlyMeansData(dataPoints:seq[DataPoint],period:(int,int)):array[Month,MeanData] =
  for datapoint in datapoints:
    if datapoint.year >= period[0] and datapoint.year <= period[1]:
      result[datapoint.month].accum += datapoint.value
      result[datapoint.month].count += 1

func calcAnoms(dataPoints:seq[DataPoint],period:(int,int)):seq[DataPoint] =
  let monthlyMeansData = dataPoints.calcMonthlyMeansData(period)
  for dataPoint in dataPoints:
    result.add dataPoint
    result[^1].anom = dataPoint.value-(
      monthlyMeansData[dataPoint.month].accum/
      monthlyMeansData[dataPoint.month].count.toFloat
    )

func parseDataItems(data,id:string,skip:int):seq[string] =
  let 
    dataItems = data.splitWhitespace
    start = if skip < dataItems.high: skip else: 0
  for dataItem in dataItems[start..<dataItems.find(id)]:
    if dataItem[0..2] != "-99": result.add dataItem

func parseYearsAndValues(dataItems:seq[string]):(seq[int],seq[float]) =
  for idx,dataItem in dataItems:
    if idx == 0 or idx mod 13 == 0:
      result[0].add dataItem.parseInt else:
      result[1].add dataItem.parseFloat

func columnFormat(dataPoints:seq[DataPoint]):seq[string] = collect: 
  for dataPoint in dataPoints:
    ($dataPoint.month)[0..2]&" "&($dataPoint.year)&
    ($dataPoint.anom)[0..5].indent(4)

func matrixFormat(dataPoints:seq[DataPoint],years:seq[int]):seq[string] =
  var idx = 0
  result.add chr(32).repeat(4).join&Month.mapIt(($it)[0..2].align(9)).join
  for year in years:
    result.add $year
    for month in Month:
      result[^1] = result[^1]&dataPoints[idx].anom.formatFloat(ffDecimal,4).align(9)
      if idx < dataPoints.high: inc idx else: break

func hasValid(period,years:seq[int]):bool =
  period.len > 1 and period[0] < period[1] and period[0] in years and period[1] in years 

proc parsePeriod(param:string,years:seq[int]):(int,int) =
  try: 
    let period = param[6..param.high].split('-').mapIt(it.parseInt) 
    if period.hasValid(years): result = (period[0],period[1]-1) else: 
      raise newException(CatchableError,"")
  except: 
    echo "Invalid normalization period parameter. Usage: -norm:startYear-endYear"
    echo "Using period: ",result

proc normalizationPeriod(years:seq[int]):(int,int) =
  result = (years[0],years[^1])
  for param in commandLineParams():
    if param.startsWith("-norm:") and param.len > 6:
      let (startYear,endYear) = param.parsePeriod(years)
      if endYear > startYear: return (startYear,endYear)

proc skip(default:int):int =
  result = default
  for param in commandLineParams():
    if param.startsWith("-skip:"):
      try: result = param[6..param.high].parseInt except: 
        echo "Invalid skip parameter - using default: ",result
        return

proc fetchAndProces(dataSet:DataSet):array[2,seq[string]] =
  let 
    data = newHttpClient().getContent(dataSet.url)
    (years,values) = data.parseDataItems(dataSet.id,skip(2)).parseYearsAndValues
    dataPoints = generateDataPoints(years,values).calcAnoms(years.normalizationPeriod)
  [dataPoints.columnFormat,dataPoints.matrixFormat(years)]  

proc readDataSets(path:string):seq[DataSet] =
  if not fileExists(path): writeFile(defaultDataSetsCfgFile,defaultDataSetsCfgLines())
  var dataSetLines:seq[string]
  for line in lines(path): dataSetLines.add line
  if dataSetLines.len mod 2 != 0:
    echo "Invalid number of lines in config file: "&path&"\n - Resetting to default"
    if path == defaultDataSetsCfgFile: writeFile(path,defaultDataSetsCfgLines())
    return @defaultDataSetsCfg 
  for idx in 0..dataSetLines.high:
    if idx mod 2 == 1: result.add (dataSetLines[idx-1],dataSetLines[idx])

proc configFile: string =
  for param in commandLineParams(): 
    if param.fileExists(): return param
  result = defaultDataSetsCfgFile

for dataSet in readDataSets(configFile()):
  echo "Fetching and processing ",dataSet.id," dataset from:\nUrl: ",dataSet.url
  for format,fileLines in dataSet.fetchAndProces: 
    let path = dataSet.id.toLower&formats[format]&".txt"
    writeFile(path,fileLines.join("\r\n"))
    echo "Wrote ",dataSet.id," dataset as ",formats[format]," to file: ",path
