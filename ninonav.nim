import ninowin

proc keyboard (k:KeyEvent) =
  if k.button == ButtonUnknown:
    echo "Rune: ",k.rune
  else:
    echo k.button

proc mouse (m:MouseEvent) =
  if mouseClicked(m.keyState):
    echo "ninonav says: hello world"

proc draw (b:var Boxy) =
  b.drawImage("bg", rect = rect(vec2(0, 0), window.size.vec2))

proc initNinoNav*() =
  addCall(newCall("ninonav",keyboard,mouse,draw,nil))

initNinoNav()
