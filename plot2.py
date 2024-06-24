import matplotlib.pyplot as plt
import sys

fileName = sys.argv[1]+"column.fwf"
print(f"plotting file: {fileName}")
values = []
for line in open(fileName):
  values.append(float(line))
plt.plot(values)
plt.show()
