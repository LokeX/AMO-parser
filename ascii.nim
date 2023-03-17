from strutils import align

for ascii in 32..126:
  if ascii-32 != 0 and (ascii-32) mod 10 == 0: stdout.write("\n")
  stdout.write ($ascii&" = "&chr(ascii)).align 10
