from algorithm import reverse
from sequtils import zip
import strutils

type Designation = enum neutral,laNina,elNino

func ninoSignal(value:float):int =
  if value >= 0.5: 1 elif value <= -0.5: -1 else: 0

func carrySignal(oldSignal,newSignal:int):int =
  if newSignal == 0 or oldSignal*newSignal < 0: 0 else: oldSignal+newSignal

func ninoSignals(values:openArray[float]):seq[int] =
  result.add carrySignal(0,values[0].ninoSignal)
  for value in values[1..values.high]: 
    result.add carrySignal(result[^1],value.ninoSignal)

iterator reversed[T](x:openArray[T]):T =
  var idx = x.high
  while idx >= x.low:
    yield x[idx]
    dec idx

func ninoDesignations(signals:openArray[int]): seq[Designation] =
  for signal in signals.reversed: 
    case signal:
      of 0: result.add neutral
      of int.low..(-5): result.add laNina
      of 5..int.high: result.add elNino
      else: result.add result[^1]
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

let 
  (labels,years,values) = parse readFile("nina34matrix.txt").splitLines
  monthlyData = zip(values,values.ninoSignals.ninoDesignations)

#Importing the terminal module breaks vs-code intellisense(- WTF?); so we delay to here
from terminal import ForegroundColor,styledWrite

func fgColor(designation:Designation):ForegroundColor =
  case designation:
    of elNino: fgRed
    of laNina: fgBlue
    of neutral: fgWhite

stdout.write labels
for indexYear,year in years:
  stdout.write "\n"&year
  for (value,ninoDesignation) in monthlyData.monthsOf indexYear:
    stdout.styledWrite ninoDesignation.fgColor,value.formatFloat(ffDecimal,4).align 9
