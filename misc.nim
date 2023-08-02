import sequtils
import sugar

template init*[T](t:var T) = t = default typeof T

iterator fiMap*[T,U](a:openArray[T],f:T -> bool,m:T -> U): U =
  for b in a:
    if f(b): yield m(b)

func fiMapSeq*[T,U](x:openArray[T],f:T -> bool,m:T -> U):seq[U] =
  # for y in x.fiMap(f,m): result.add y
  x.fimap(f,m).toSeq
  
proc muMap*[T,U](x:var openArray[T],m:T -> U) =
  var idx = 0
  while idx <= x.high:
    x[idx] = m(x[idx])
    inc idx

iterator reversed*[T](x:openArray[T]):T {.inline.} =
  var idx = x.high
  while idx >= x.low:
    yield x[idx]
    dec idx

iterator zipem*[T,U](x:openArray[T],y:openArray[U]): (T,U) =
  var idx = 0
  let idxEnd = min(x.high,y.high)
  while idx <= idxEnd:
    yield (x[idx],y[idx])
    inc idx

func zipTuple*[T,U](x:(seq[T],seq[U])):seq[(T,U)] = zip(x[0],x[1])

func flatMap*[T](x:seq[seq[T]]):seq[T] =
  for y in x:
    for z in y:
      result.add z

var t1 = (1, "foo")
var t2 = default(typeof(t1))
echo t2
for v1, v2 in fields(t1, t2): v2 = v1
echo t1
echo t2

when isMainModule:
  var 
    test = @[1,2,3,4,5,6,7,8]
    test2 = test
  echo test.reversed.toSeq
  echo test.fiMapSeq(y => y mod 2 == 0, x => (x*2).toFloat)
  for t in test.fiMap(y => y mod 2 == 0, x => x*2): echo t
  for t in zipem(test,test2): echo t
  test.muMap(x => x*3)
  echo test
  echo zipTuple (test,test2)
