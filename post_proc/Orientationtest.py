#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu May  7 09:35:48 2020

@author: nicklauersdorf
"""

'''
#                           This is an 80 character line                       #
What does this file do?
(Reads single argument, .gsd file name)
1.) Read in .gsd file of particle positions
2.) Mesh the space
3.) Loop through tsteps and ...
3a.) Place all particles in appropriate mesh grid
3b.) Loop through all particles ...
3b.i.) Compute distance to every particle in adjacent grids
3.b.ii.) If distance is less than LJ cutoff, store as effective diameter
3c.) Plot particle with effective diameter as patch
4.) Generate movie from frames
'''

import sys
import os

#gsdPath='/Users/nicklauersdorf/hoomd-blue/build/04_26_20_parent/'
gsdPath='/Volumes/External/04_01_20_parent/gsd/'# /hoomd-blue/build/04_26_20_parent/'
hoomdPath='/Users/nicklauersdorf/hoomd-blue/build'
img_files='/Users/nicklauersdorf/hoomd-blue/build/img_files2/'


import gsd
from gsd import hoomd
from gsd import pygsd

import freud
from freud import parallel
from freud import box
from freud import density
from freud import cluster

import math
import numpy as np
from scipy import stats

import matplotlib
#matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.collections
from matplotlib import collections  as mc
from matplotlib import lines

def computeR(part1, part2):
    """Computes distance"""
    return np.sqrt(((part2[0]-part1[0])**2)+((part2[1]-part1[1])**2))

def computeA(diameter):
    """Computes area of circle"""
    radius = diameter / 2.0
    return np.pi * (radius**2)

def getDistance(point1, point2x, point2y):
    """Find the distance between two points"""
    distance = np.sqrt((point2x - point1[0])**2 + (point2y - point1[1])**2)
    return distance
    
def quatToVector(quat, type, peZero, peOne):
    "Takes quaternion, returns orientation vector"
    if type == 0:
        mag = peZero
    else:
        mag = peOne
    x = (quat[1] / math.sqrt(1.-quat[0]**2))*mag
    y = (quat[2] / math.sqrt(1.-quat[0]**2))*mag
    act_vec = (x, y)
    return act_vec
    
def quatToAngle(quat):
    "Take vector, output angle between [-pi, pi]"
    mag=150

    x = quat[1]*mag#(quat[1] / math.sqrt(1.-quat[0]**2))*mag
    y = quat[2]*mag#(quat[2] / math.sqrt(1.-quat[0]**2))*mag
    
    rad = math.atan2(y, x)
    #rad = 2 * math.acos(quat[0])
    print(rad)
    return rad
def quatToAngle2(quat):
    "Take quaternion, output angle between [0, 2pi]"
#quat[2]
    

    #theta += np.pi
    return theta
myShrink = 0.6  # shrink the colorbars
padCbar = 0.02
padCbarLabel = 10

# Make a list for orientation arrow colorbar
xPos = 1.13
dx = [0., -0.05, -0.05, -0.05, 0, 0.05, 0.05, 0.05, 0]
dy = [0.05, 0.05, 0, -0.05, -0.05, -0.05, 0, 0.05, 0.05]
for i in range(0, len(dx)):
    dx[i] = dx[i] / 2.
    dy[i] = dy[i] / 2.
xA = [xPos, xPos, xPos, xPos, xPos, xPos, xPos, xPos, xPos]
yA = [0., 1./8., 2./8., 3./8., 0.5, 5./8., 6./8., 7./8., 1.0]

# Command line arguments
part_perc_a = int(50)
part_frac_a = float(part_perc_a) / 100.0
pe_a = int(150)
pe_b = int(150)
ep = int(1)
partNum=int(10000)

myfile = "pa" + str(pe_a) + "_pb" + str(pe_b) + "_xa" + str(part_perc_a) + "_ep" + str(ep) + "_pNum" + str(partNum)+".gsd"


phi = 0.6
intPhi = 60
dtau = 0.000001
    
# Create outfile name from infile name
#file_name = os.path.basename(infile)
#outfile, file_extension = os.path.splitext(file_name)   # get base name
#out = outfile + "_frame_"

# Get dumps to output
f = hoomd.open(name=gsdPath+myfile, mode='rb')  # open gsd file with hoomd
dumps = int(f.__len__())                # get number of timesteps dumped
start = 0
#start = dumps - 1                       # gives first frame to read
end = dumps                             # gives last frame to read
#end = 20

def getNBins(length, minSz=(2**(1./6.))):
    "Given box size, return number of bins"
    initGuess = int(length) + 1
    nBins = initGuess
    # This loop only exits on function return
    while True:
        if length / nBins > minSz:
            return nBins
        else:
            nBins -= 1

# Round up size of bins to account for floating point inaccuracy
def roundUp(n, decimals=0):
    multiplier = 10 ** decimals
    return math.ceil(n * multiplier) / multiplier

# Compute mesh
r_cut = 2**(1./6.)

# Access file frames
with hoomd.open(name=gsdPath+myfile, mode='rb') as t:

    # Take first snap for box
    snap = t[0]
    first_tstep = snap.configuration.step
    box_data = snap.configuration.box
    # Get box dimensions
    l_box = box_data[0]
    h_box = l_box / 2.
    a_box = l_box * l_box
    nBins = (getNBins(l_box, r_cut))
    sizeBin = roundUp((l_box / nBins), 6)
    partNum = len(snap.particles.typeid)

    # Loop through snapshots
    for j in range(start, 3001):
    
        # Get the current snapshot
        snap = t[j]
        # Easier accessors
        pos = snap.particles.position               # position
        pos[:,-1] = 0.0
        xy = np.delete(pos, 2, 1)
        typ = snap.particles.typeid                 # type
        tst = snap.configuration.step               # timestep
        tst -= first_tstep                          # normalize by first timestep
        tst *= dtau                                 # convert to Brownian time
        ori = snap.particles.orientation            # orientation
        ang = np.array(list(map(quatToAngle, ori))) # convert to [-pi, pi]
        # Create frame pad for images
        pad = str(j).zfill(4)
        
        # Plot the figure
        fig, ax = plt.subplots(1, 1)
        sc = ax.scatter(pos[:,0], pos[:,1], c=ang, edgecolor='none', s=15., cmap='hsv')
        ax.text(0.95, 0.025, s=r'$\tau_{r}=$' + '{:0.1f}'.format(tst*3.),
                horizontalalignment='right', verticalalignment='bottom',
                transform=ax.transAxes,
                fontsize=18,
                bbox=dict(facecolor=(1,1,1,0.5), edgecolor=(0,0,0,1), boxstyle='round, pad=0.1'))
        # Plot the orientation colorbar
        cbar = fig.colorbar(sc, ax=ax, pad=0.03)
        cbar.set_ticks([])
        # Add arrows for colorbar
        for k in range(0, len(dx)):
            ax.arrow(x=xA[k] - (dx[k]), y=yA[k] - (dy[k]/2.), dx=dx[k], dy=dy[k], head_length=0.025,
                     width=0.01, transform=ax.transAxes, clip_on=False, color=plt.cm.hsv(float(k)/8.))
        ax.set_xlim(-h_box, h_box)
        ax.set_ylim(-h_box, h_box)
        ax.axes.set_xticks([])
        ax.axes.set_yticks([])
        ax.axes.set_xticklabels([])
        ax.axes.set_yticks([])
        ax.set_aspect('equal')
        plt.subplots_adjust(0.02,0.02,0.96,0.96)
        plt.savefig(img_files+"test_fm" + pad + ".png", dpi=150)
        plt.close()