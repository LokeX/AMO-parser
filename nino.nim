from algorithm import reverse
import strutils
import sequtils

type Designation = enum laNina,elNino,neutral

func ninoSignal(val:float):int =
  if val >= 0.5: result = 1 elif val <= -0.5: result = -1 else: result = 0

func signalSwitch(oldSignal,newSignal:int):int =
  if newSignal == 0: result = 0 else: result = oldSignal+newSignal

func ninoSignals(vals:openArray[float]):seq[int] =
  result.add signalSwitch(0,vals[0].ninoSignal)
  for val in vals[1..vals.high]: result.add signalSwitch(result[^1],val.ninoSignal)

iterator inReverse[T](x:openArray[T]):T {.inline.} =
  var idx = x.high
  while idx >= x.low:
    yield x[idx]
    dec idx

func ninoDesignations(signals:openArray[int]):seq[Designation] =
  var switch:int
  for signal in signals.inReverse:
    if signal <= -5 or signal >= 5: 
      switch = signal
    elif signal == 0: 
      switch = 0
    if signal < 0 and switch < 0:
      result.add laNina
    elif signal > 0 and switch > 0:
      result.add elNino
    else: result.add neutral
  reverse result

func parse(fileLines:openArray[string]):(seq[string],seq[float]) =
  for line in fileLines[1..fileLines.high]:
    result[0].add line[0..3]
    for valStr in line[4..line.high].splitWhitespace: 
      result[1].add valStr.parseFloat

func monthsIn[T](months:openArray[T],indexYear:int):seq[T] =
  let 
    startMonth = indexYear*12
    endMonth = if startMonth+11 > months.high: months.high else: startMonth+11
  months[startMonth..endMonth]

proc readFileLines(path:string):seq[string] =
  for line in lines path: result.add line

let 
  fileLines = readFileLines("nina34matrix.txt")
  (years,vals) = parse fileLines
  monthlyData = zip(vals,vals.ninoSignals.ninoDesignations)
  months = fileLines[0]

import terminal #Last possible moment: the import bothers vs-code intellisense - just weird

func fgColor(designation:Designation):ForegroundColor =
  case designation
    of elNino: fgRed
    of laNina: fgBlue
    of neutral: fgWhite

stdout.write(months.indent 4)
for indexYear,yearLabel in years:
  stdout.write("\n"&yearLabel.indent 4)
  for (value,ninoDesignation) in monthlyData.monthsIn indexYear:
    stdout.styledWrite(ninoDesignation.fgColor,value.formatFloat(ffDecimal,4).align 9)
