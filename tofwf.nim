import sequtils
import strutils

const
  inOutFiles:array[2,tuple[inFile,outFile:string]] = [
    ("amocolumn.txt","amocolumn.fwf"),
    ("nina34column.txt","nina34column.fwf")
  ]

for files in inOutFiles:
  let lis = toseq lines files.inFile
  writeFile(files.outFile,
    lis[lis.low+1..lis.high]
    .mapIt(it.substr 12).join "\n"
  )
  echo "read file: ",files.inFile
  echo "wrote file: ",files.outFile
