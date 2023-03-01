import httpClient
import strutils
import sequtils
import times

type 
  DataPoint = tuple
    year:int
    month:Month
    value,anom:float
  MeansData = array[Month,tuple[accum:float,count:int]]
 
func generateDataPoints(years:seq[int],values:seq[float]):seq[DataPoint] =
  var idx = 0
  for year in years:
    for month in Month:
      result.add (year,month,values[idx],0.0)
      if idx < values.high:inc idx else:return

func meansData(dataPoints:seq[DataPoint]):MeansData =
  for datapoint in datapoints:
    result[datapoint.month].accum += datapoint.value
    result[datapoint.month].count += 1

func calcAnoms(dataPoints:seq[DataPoint]):seq[DataPoint] =
  let meansData = dataPoints.meansData
  for dataPoint in dataPoints:
    result.add dataPoint
    result[^1].anom = dataPoint.value-(
      meansData[dataPoint.month].accum/meansData[dataPoint.month].count.toFloat
    )

func parseDataItems(data:string):seq[string] =
  let
    dataItems = data.splitWhitespace
    startIdx = 2
    endIdx = dataItems.find("AMO")
  for idx,dataItem in dataItems:
    if idx in startIdx..<endIdx and dataItem[0] != '-': 
      result.add dataItem

func parseYearsAndValues(dataItems:seq[string]):(seq[int],seq[float]) =
  var 
    years:seq[int]
    values:seq[float]
  for idx,dataItem in dataItems:
    if idx == 0 or idx mod 13 == 0:
      years.add dataItem.parseInt
    else:
      values.add dataItem.parseFloat
  (years,values)

func parseData(data:string): (seq[DataPoint],seq[int]) =
  let (years,values) = data.parseDataItems.parseYearsAndValues
  (generateDataPoints(years,values).calcAnoms,years)

func columnFormat(dataPoints:seq[DataPoint]):seq[string] =
  for dataPoint in dataPoints:
    let date = ($dataPoint.month)[0..2]&" "&($dataPoint.year)
    result.add date&($dataPoint.anom)[0..5].indent(4)

func matrixFormat(dataPoints:seq[DataPoint],years:seq[int]):seq[string] =
  var idx = 0
  result.add " ".cycle(4).join&Month.mapIt(($it)[0..2].align(9)).join
  for year in years:
    var line = $year
    for month in Month:
      let anom = $dataPoints[idx].anom
      line = line&anom[0..(if dataPoints[idx].anom < 0:6 else:5)].align(9)
      if idx == dataPoints.high: break
      inc idx
    result.add line
  result.add "-".cycle(result[^2].len).join

proc output(path:string,lines:seq[string]) =
  var txtFile = open(path,fmWrite)
  defer: close(txtFile)
  for line in lines: 
    txtFile.writeLine(line)
    echo line

const
  fileNameCol = "anomscol.txt"
  fileNameMatrix = "anomsmatrix.txt"
  url = "https://psl.noaa.gov/data/correlation/amon.us.long.mean.data"

let (datapoints,years) = newHttpClient().getContent(url).parseData
output(fileNameCol,dataPoints.columnFormat)
output(fileNameMatrix,dataPoints.matrixFormat(years))
