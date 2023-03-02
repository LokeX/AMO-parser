import httpClient
import strutils
import sequtils
import times
import sugar

const 
  inOuts = [
    ("https://psl.noaa.gov/data/correlation/amon.us.long.mean.data",
    "amocol.txt","amomatrix.txt","AMO"),
    ("https://psl.noaa.gov/gcos_wgsp/Timeseries/Data/nino34.long.data",
    "ninocol.txt","ninomatrix.txt","NINA34")
  ]

type 
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

proc output(path:string,lines:seq[string]) =
  var txtFile = open(path,fmWrite)
  defer: close(txtFile)
  for line in lines: 
    txtFile.writeLine(line)
    echo line

proc inOut(inOuts:openArray[(string,string,string,string)]) =
  for io in inOuts:
    let 
      (url,colFile,matrixFile,id) = io
      (datapoints,years) = newHttpClient().getContent(url).parseData(id)
      puts = [
        (colFile,dataPoints.columnFormat),
        (matrixFile,dataPoints.matrixFormat(years))
      ]
    for put in puts: output(put[0],put[1])

inOut(inOuts)
