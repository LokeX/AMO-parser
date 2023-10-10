import sequtils
import strutils
import os

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

# import nimpy
# import nimpy/py_lib
# pyInitLibPath("C:\\Users\\perni\\AppData\\Local\\Programs\\Python\\Python312\\python312.dll")

# let 
#   plt = pyImport("matplotlib.pyplot")
#   fileName = paramStr(1)&"column.fwf"

# echo "plotting file: ",fileName
# discard plt.plot(fileName.lines.toSeq.mapIt(it.parseFloat))
# discard plt.show()

