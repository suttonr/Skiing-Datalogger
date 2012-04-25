import csv
import math
import string
import sys
import getopt
import time
import numpy as np
import matplotlib
matplotlib.use('GTKAgg') # do this before importing pylab

import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D

usage="""
USAGE: plot.py -i | --input=filename  -o | --outputfile=filename
"""

validArgs='i:o:'
longArgs=["input=","output="]
infile = "accel6.csv"
outfile = "accel6-calc.csv"

try:
        opts, args = getopt.getopt(sys.argv[1:], validArgs,longArgs)
except:
        print usage
        sys.exit(2)

for opt,arg in opts:
        if opt in ("-i","--input"):
                infile=arg
        elif opt in ("-o","--output"):
                outfile=arg

try:
	datafile = open(infile);
except:
	print "Err: Invalid Input File."
	sys.exit(2)

print "Infile %s" % infile

headerReader = csv.reader(datafile)
headers = headerReader.next()
myRead = csv.DictReader(datafile, headers)
mydata={}

# Read in data
for d in myRead:
    mydata[d["time"]]=d

# Convert to G units (rx,ry,rz)
for x in mydata:
    mydata[x]['rx'] = (string.atoi(mydata[x]['ax'])*3.3/1023-1.65)/.800
for x in mydata:
    mydata[x]['ry'] = (string.atoi(mydata[x]['ay'])*3.3/1023-1.65)/.800
for x in mydata:
    mydata[x]['rz'] = (string.atoi(mydata[x]['az'])*3.3/1023-1.65)/.800

# Compute length of vector (R)
for x in mydata:
    mydata[x]['R'] = math.sqrt( math.pow(mydata[x]['rx'],2) + math.pow(mydata[x]['ry'],2) + math.pow(mydata[x]['rz'],2))

# Compute angular components of vector (axr,ayr,azr)
for x in mydata:
    mydata[x]['axr'] = math.acos(mydata[x]['rx']/mydata[x]['R'])
for x in mydata:
    mydata[x]['ayr'] = math.acos(mydata[x]['ry']/mydata[x]['R'])
for x in mydata:
    mydata[x]['azr'] = math.acos(mydata[x]['rz']/mydata[x]['R'])

# Compute distance tripet ( angles w/ vector length 1 ) (cosx,cosy,coz)
for x in mydata:
    mydata[x]['cosz'] = mydata[x]['rz']/mydata[x]['R']
for x in mydata:
    mydata[x]['cosy'] = mydata[x]['ry']/mydata[x]['R']
for x in mydata:
    mydata[x]['cosx'] = mydata[x]['rx']/mydata[x]['R']

fig = plt.figure()

ax = fig.gca(projection='3d')

def animate():
    tstart = time.time()                 # for profiling
    #x = np.arange(0, 2*np.pi, 0.01)        # x-array
    #line, = ax.plot([0,, np.sin(x))
    line, = ax.plot([0,1],[0,1],[0,1])
    ax.set_xlim3d(-1, 1)
    ax.set_ylim3d(-1, 1)
    ax.set_zlim3d(-1, 1)
    ax.set_xlabel("X Axis")
    ax.set_ylabel("Y Axis")
    ax.set_zlabel("Z Axis")
    
    for x in sorted(mydata.iterkeys())[::5]:
      print mydata[x]['rx']
      line.set_xdata([0,mydata[x]['ry']])
      line.set_ydata([0,mydata[x]['rx']])
      line.set_3d_properties([0,mydata[x]['rz']])
      #rx = mydata[x]['rx']
      #ry = mydata[x]['ry']
      #rz = mydata[x]['rz']
      #line.set_verts([0,rx],[0,ry],[0,rz])
      #ax.plot([0,rx],[0,ry],[0,rz])
      fig.canvas.draw()
    #for i in np.arange(1,200):
    #    line.set_ydata(np.sin(x+i/10.0))  # update the data
    #    fig.canvas.draw()                         # redraw the canvas
    print 'FPS:' , 200/(time.time()-tstart)
    raise SystemExit

import gobject
print 'adding idle'
gobject.idle_add(animate)
print 'showing'
plt.show()


## Write out data
#try:
#	myfile = open(outfile, 'w')
#except:
#        print "Err: Invalid Input File."
#        sys.exit(2)
#
#print "Output saved to  %s" % outfile
#mywriter = csv.writer(myfile)
#mywriter.writerow(mydata[mydata.keys()[0]].keys())
#for x in sorted(mydata.iterkeys()):
#    mywriter.writerow(mydata[x].values())
#datafile.close()
###myfile.close()
