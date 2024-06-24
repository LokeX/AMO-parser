import strutils
import sequtils

const
  inFile = "nina34column.txt"
  outFile = "nina34cline.txt"

type
  Item = tuple[label:string,value:float]

var
  clines:seq[Item]
  words:seq[string]
  first = true

for line in lines inFile:
  try:
    if first: first = false
    else:
      words = line.splitWhitespace
      echo words
      clines.add (
        words[0]&" "&words[1],
        words[^1].parseFloat+(if clines.len > 0:clines[^1].value else:0)
      )
      echo clines[^1]
  except:
    echo "discarded:"
    echo getCurrentExceptionMsg()
  writeFile(
    outFile,
    clines.mapIt(
      it.label&" "&(it.value.formatFloat(ffDecimal,2).align 9)
    ).join "\n"
  )
