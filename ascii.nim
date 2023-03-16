from strutils import align

iterator rangeCount(slice:HSlice[int,int]): (int,int) =
  var (count,idx) = (0,slice.a)
  while idx <= slice.b:
    yield (count,idx)
    inc count
    inc idx
    
for count,ascii in rangeCount 32..126:
  if count != 0 and count mod 10 == 0: stdout.write("\n")
  stdout.write ($ascii&" = "&chr(ascii)).align 10
