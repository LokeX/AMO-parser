from algorithm import reverse
from sequtils import zip
import strutils

type Designation = enum laNina,elNino,neutral

func ninoSignal(val:float):int =
  if val >= 0.5: 
    result = 1 
  elif val <= -0.5: 
    result = -1 
  else: 
    result = 0

func signalSwitch(oldSignal,newSignal:int):int =
  if newSignal == 0: result = 0  else: 
    result = oldSignal+newSignal

func ninoSignals(vals:openArray[float]):seq[int] =
  result.add signalSwitch(0,vals[0].ninoSignal)
  for val in vals[1..vals.high]: 
    result.add signalSwitch(result[^1],val.ninoSignal)

iterator reversed[T](x:openArray[T]):T {.inline.} =
  var idx = x.high
  while idx >= x.low:
    yield x[idx]
    dec idx

func ninoDesignations(signals:openArray[int]):seq[Designation] =
  var switch = 0
  for signal in signals.reversed:
    if signal == 0:
      switch = 0
    else:
      switch = signal
    if signal < 0 and switch < 0:
      result.add laNina
    elif signal > 0 and switch > 0:
      result.add elNino
    else: result.add neutral
  reverse result

func parse(fileLines:openArray[string]):(string,seq[string],seq[float]) =
  result[0] = fileLines[0]&"\n"&fileLines[1]
  for line in fileLines[2..fileLines.high]:
    result[1].add line[0..3]
    for valStr in line[4..line.high].splitWhitespace: 
      result[2].add valStr.parseFloat

func monthsOf[T](months:openArray[T],indexYear:int):seq[T] =
  let 
    startMonth = indexYear*12
    endMonth = if startMonth+11 > months.high: months.high else: startMonth+11
  months[startMonth..endMonth]

proc fileLines(path:string):seq[string] =
  for line in lines path: result.add line

let 
  (labels,years,values) = parse fileLines "nina34matrix.txt"
  monthlyData = zip(values,values.ninoSignals.ninoDesignations)

#Importing the terminal module makes vs-code intellisense go weird, so we delay to here
from terminal import ForegroundColor,styledWrite

func fgColor(designation:Designation):ForegroundColor =
  case designation
    of elNino: fgRed
    of laNina: fgBlue
    of neutral: fgWhite

stdout.write labels
for indexYear,year in years:
  stdout.write "\n"&year
  for (value,ninoDesignation) in monthlyData.monthsOf indexYear:
    stdout.styledWrite ninoDesignation.fgColor,value.formatFloat(ffDecimal,4).align 9
