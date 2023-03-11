import strutils
import algorithm

type 
  Designation = enum laNina,elNino,neutral
  DataPoint = tuple[value:string,designation:Designation]

func ninoSignal(val:float):int =
  if val >= 0.5: result = 1 elif val <= -0.5: result = -1 else: result = 0

func signalToggle(oldSignal,newSignal:int):int =
  if newSignal == 0: result = 0 else: result = oldSignal+newSignal

func ninoSignals(vals:seq[float]):seq[int] =
  result.add signalToggle(0,vals[0].ninoSignal)
  for val in vals[1..vals.high]: result.add signalToggle(result[^1],val.ninoSignal)

func ninoDesignations(signals:seq[int]):seq[Designation] =
  var tick:int
  for idx in countdown(signals.high,signals.low):
    if signals[idx] <= -5 or signals[idx] >= 5: 
      tick = signals[idx]
    elif signals[idx] == 0: 
      tick = 0
    if signals[idx] < 0 and tick < 0:
      result.add laNina
    elif signals[idx] > 0 and tick > 0:
      result.add elNino
    else: result.add neutral
  result.reverse

func parseVals(fileLines:seq[string]):seq[float] =
  for line in fileLines[1..fileLines.high]:
    for valStr in line[4..line.high].splitWhitespace: result.add valStr.parseFloat

func generateDataPoints(vals:seq[float],designations:seq[Designation]):seq[DataPoint] =
  for i,val in vals: result.add (val.formatFloat(ffDecimal,4).align(9),designations[i])

func generateYears(fileLines:seq[string]):seq[string] =
  for line in fileLines[1..fileLines.high]: result.add line[0..3].strip

proc readFileLines(path:string):seq[string] =
  for line in lines(path): result.add line

let 
  fileLines = readFileLines("nina34matrix.txt")
  vals = fileLines.parseVals
  designations = vals.ninoSignals.ninoDesignations
  dataPoints = generateDataPoints(vals,designations)
  months = fileLines[0]
  years = fileLines.generateYears

import terminal #Last possible moment: the import bothers vs-code intellisense - just weird

func ninoColor(designation:Designation):ForegroundColor =
  case designation
    of elNino: fgRed
    of laNina: fgBlue
    of neutral: fgWhite

stdout.write(months.indent(4))
for i,year in years:
  let offset = i*12
  stdout.write("\n"&year.indent(4))
  for month in dataPoints[offset..<offset+12]:
    stdout.styledWrite(month.designation.ninoColor,month.value)
