import httpClient
import strutils
import sequtils
import times

type 
  DataPoint = tuple[year:int,month:Month,value,anom:float]
  MeanData = tuple[accum:float,count:int]
 
func generateDataPoints(years:seq[int],values:seq[float]):seq[DataPoint] =
  var idx = 0
  for year in years:
    for month in Month:
      result.add (year,month,values[idx],0.0)
      if idx < values.high:inc idx else:return

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

func parseDataItems(data:string):seq[string] =
  let dataItems = data.splitWhitespace
  for dataItem in dataItems[2..<dataItems.find("AMO")]:
    if dataItem[0] != '-': result.add dataItem

func parseYearsAndValues(dataItems:seq[string]):(seq[int],seq[float]) =
  for idx,dataItem in dataItems:
    if idx == 0 or idx mod 13 == 0:
      result[0].add dataItem.parseInt else:
      result[1].add dataItem.parseFloat

func parseData(data:string): (seq[DataPoint],seq[int]) =
  let (years,values) = data.parseDataItems.parseYearsAndValues
  (generateDataPoints(years,values).calcAnoms,years)

func columnFormat(dataPoints:seq[DataPoint]):seq[string] =
  for dataPoint in dataPoints:
    result.add (
      ($dataPoint.month)[0..2]&" "&($dataPoint.year)&
      ($dataPoint.anom)[0..5].indent(4)
    )

func matrixFormat(dataPoints:seq[DataPoint],years:seq[int]):seq[string] =
  var idx = 0
  result.add chr(32).repeat(4).join&Month.mapIt(($it)[0..2].align(9)).join
  for year in years:
    var line = $year
    for month in Month:
      let anom = dataPoints[idx].anom
      line = line&($anom)[0..(if anom < 0:6 else:5)].align(9)
      if idx == dataPoints.high: break
      inc idx
    result.add line
  result.add '-'.repeat(result[^2].len).join

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
