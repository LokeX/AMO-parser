from os.path import exists
import sys

fileName = sys.argv[1]+"column.txt"
if exists(fileName):
  import matplotlib.pyplot as plt
  print(f"plotting file: {fileName}")
  values,labels,ticks = [],[],[]
  ticker = 0
  first = True
  for line in open(fileName):
    l = line.strip().split()
    if first:
      plt.title(line)
      first = False
    else:
      if l[0].endswith("Jan") and (int(l[0][:4])%8 == 0):
        labels.append(l[0])
        ticks.append(ticker)
      values.append(float(l[1]))
      ticker += 1
  plt.plot(values)
  plt.xticks(ticks,labels)
  plt.xticks(rotation = 45)
  plt.xticks(fontsize = 5)
  plt.grid()
  plt.show()
