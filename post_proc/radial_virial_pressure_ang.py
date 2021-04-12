'''
#                           This is an 80 character line                       #
What does this file do?
(Reads single argument, .gsd file name)
1.) Get center of mass
'''

import sys
from gsd import hoomd
import freud
import numpy as np
import math

#from descartes.patch import PolygonPatch
# Run locally
hoomdPath='/Users/nicklauersdorf/hoomd-blue/build/'#'/nas/home/njlauers/hoomd-blue/build/'#Users/nicklauersdorf/hoomd-blue/build/'
#gsdPath='/Users/nicklauersdorf/hoomd-blue/build/04_01_20_parent/'#'/Volumes/External/04_01_20_parent/gsd/'
# Run locally
sys.path.insert(0,hoomdPath)

r_cut=2**(1/6)
# Get infile and open
inFile = str(sys.argv[1])

if inFile[0:7] == "cluster":
    add = 'cluster_'
else:
    add = ''
def smooth(y, box_pts):
    box = np.ones(box_pts)/box_pts
    y_smooth = np.convolve(y, box, mode='same')
    return y_smooth
#inFile='pa300_pb300_xa50_ep1.0_phi60_pNum100000.gsd'
#inFile = 'cluster_pa400_pb350_phi60_eps0.1_xa0.8_align3_dtau1.0e-06.gsd'
#inFile='pa400_pb500_xa20_ep1.0_phi60_pNum100000.gsd'
outPath='/Volumes/External/mono_test/'#'/pine/scr/n/j/njlauers/scm_tmpdir/total_phase_dens_updated/'#'Users/nicklauersdorf/hoomd-blue/build/04_01_20_parent/'#'/Volumes/External/04_01_20_parent/gsd/'
#outPath='/pine/scr/n/j/njlauers/scm_tmpdir/alignment_sparse/rerun2/'#Users/nicklauersdorf/hoomd-blue/build/test4/'#pine/scr/n/j/njlauers/scm_tmpdir/surfacetens/'
#outPath='/Users/nicklauersdorf/hoomd-blue/build/gsd/'
outF = inFile[:-4]

f = hoomd.open(name=inFile, mode='rb')

#Label simulation parameters
peA = float(sys.argv[2])
peB = float(sys.argv[3])
parFrac_orig = float(sys.argv[4])
if parFrac_orig<1.0:
    parFrac=parFrac_orig*100.
else:
    parFrac=parFrac_orig
eps = float(sys.argv[5])
peNet=peA*(parFrac/100)+peB*(1-(parFrac/100))
#Determine which activity is the slow activity or if system is monodisperse

try:
    phi = float(sys.argv[6])
    intPhi = int(phi)
    phi /= 100.
except:
    phi = 0.6
    intPhi = 60

try:
    dtau = float(sys.argv[7])
except:
    dtau = 0.000001

# Set some constants
kT = 1.0                        # temperature
threeEtaPiSigma = 1.0           # drag coefficient
sigma = 1.0                     # particle diameter
D_t = kT / threeEtaPiSigma      # translational diffusion constant
D_r = (3.0 * D_t) / (sigma**2)  # rotational diffusion constant
tauBrown = (sigma**2) / D_t     # brownian time scale (invariant)

def legend_without_duplicate_labels(ax):
    handles, labels = ax.get_legend_handles_labels()
    unique = [(h, l) for i, (h, l) in enumerate(zip(handles, labels)) if l not in labels[:i]]
    ax.legend(*zip(*unique))
    
def computeVel(activity):
    "Given particle activity, output intrinsic swim speed"
    # This gives:
    # v_0 = Pe * sigma / tau_B = Pe * sigma / 3 * tau_R
    velocity = (activity * sigma) / (3 * (1/D_r))
    return velocity

def computeActiveForce(velocity):
    "Given particle activity, output repulsion well depth"
    # This is multiplied by Brownian time and gives:
    #          Pe = 3 * v_0 * tau_R / sigma
    # the conventional description of the Peclet number
    activeForce = velocity * threeEtaPiSigma
    return activeForce

def computeEps(alpha, activeForce):
    "Given particle activity, output repulsion well depth"
    # Here is where we will be testing the ratio we use (via alpha)
    epsilon = (alpha * activeForce * sigma / 24.0) + 1.0
    # Add 1 because of integer rounding
    epsilon = int(epsilon) + 1
    return epsilon

def avgCollisionForce(peNet):
    '''Computed from the integral of possible angles'''
    # A vector sum of the six nearest neighbors
    magnitude = np.sqrt(28)
    return (magnitude * peNet) / (np.pi) 

def maximum(a, b, c, d): 
  
    if (a >= b) and (a >= c) and (a >= d): 
        largest = a 
    elif (b >= a) and (b >= c) and (b >= d): 
        largest = b 
    elif (c >= a) and (c >= b) and (c >= d):
        largest = c
    else: 
        largest = d
          
    return largest 

def minimum(a, b, c, d): 
  
    if (a <= b) and (a <= c) and (a <= d): 
        smallest = a 
    elif (b <= a) and (b <= c) and (b <= d): 
        smallest = b 
    elif (c <= a) and (c <= b) and (c <= d):
        smallest = c
    else: 
        smallest = d
          
    return smallest 
def quatToAngle(quat):
    "Take vector, output angle between [-pi, pi]"
    #print(quat)
    r = quat[0]
    x = quat[1]
    y = quat[2]
    z = quat[3]
    #print(2*math.atan2(x,r))
    rad = math.atan2(y, x)#(2*math.acos(r))#math.atan2(y, x)#
    
    return rad
def computeTauLJ(epsilon):
    "Given epsilon, compute lennard-jones time unit"
    tauLJ = ((sigma**2) * threeEtaPiSigma) / epsilon
    return tauLJ
def ljForce(r, eps, sigma=1.):
    '''Compute the Lennard-Jones force'''
    div = (sigma/r)
    dU = (24. * eps / r) * ((2*(div**12)) - (div)**6)
    return dU
def getLat(peNet, eps):
    '''Get the lattice spacing for any pe'''
    if peNet == 0:
        return 2.**(1./6.)
    out = []
    r = 1.112
    skip = [0.1, 0.01, 0.001, 0.0001, 0.00001, 0.000001, 0.0000001, 0.00000001]
    for j in skip:
        while ljForce(r, eps) < avgCollisionForce(peNet):
            r -= j
        r += j
    return r  
#Calculate activity-softness dependent variables
lat=getLat(peNet,eps)

tauLJ=computeTauLJ(eps)
dt = dtau * tauLJ                        # timestep size


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
    
matplotlib.rc('font', serif='Helvetica Neue') 
matplotlib.rcParams.update({'font.size': 8})
matplotlib.rcParams['agg.path.chunksize'] = 999999999999999999999.
matplotlib.rcParams['xtick.direction'] = 'in'
matplotlib.rcParams['ytick.direction'] = 'in'
matplotlib.rcParams['lines.linewidth'] = 0.5
matplotlib.rcParams['axes.linewidth'] = 1.5
            
def computeDist(x1, y1, x2, y2):
    '''Compute distance between two points'''
    return np.sqrt( ((x2-x1)**2) + ((y2 - y1)**2) )
    
def computeFLJ(r, dx, dy, eps):
    sig = 1.
    f = (24. * eps / r) * ( (2*((sig/r)**12)) - ((sig/r)**6) )
    fx = f * (dx) / r
    fy = f * (dy) / r
    return fx, fy

def computeTauPerTstep(epsilon, mindt=0.000001):
    '''Read in epsilon, output tauBrownian per timestep'''
#    if epsilon != 1.:
#        mindt=0.00001
    kBT = 1.0
    tstepPerTau = float(epsilon / (kBT * mindt))
    return 1. / tstepPerTau

def roundUp(n, decimals=0):
    '''Round up size of bins to account for floating point inaccuracy'''
    multiplier = 10 ** decimals
    return math.ceil(n * multiplier) / multiplier
    
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
def distComps(point1, point2x, point2y):
    '''Given points output x, y and r'''
    dx = point2x - point1[0]
    dy = point2y - point1[1]
    r = np.sqrt((dx**2) + (dy**2))
    return dx, dy, r
def findBins(lookN, currentInd, maxInds):
    '''Get the surrounding bin indices'''
    maxInds -= 1
    left = currentInd - lookN
    right = currentInd + lookN
    binsList = []
    for i in range(left, right):
        ind = i
        if i > maxInds:
            ind -= maxInds
        binsList.append(ind)
    return binsList
f = hoomd.open(name=inFile, mode='rb')


# Grab files
slowCol = '#d8b365'
fastCol = '#5ab4ac'


box_data = np.zeros((1), dtype=np.ndarray)  # box dimension holder
r_cut = 2**(1./6.)                          # potential cutoff
tauPerDT = computeTauPerTstep(epsilon=eps)  # brownian time per timestep

                        
outTxt = 'CoM_ang_' + outF + '.txt'
                
g = open(outTxt, 'w+') # write file headings
g.write('tauB'.center(15) + ' ' +\
                        'clust_size'.center(15) + ' ' +\
                        'min_ang'.center(15) + ' ' +\
                        'max_ang'.center(15) + ' ' +\
                        'radius'.center(15) + ' ' +\
                        'rad_bin'.center(15) + ' ' +\
                        'press_vp'.center(15) + ' ' +\
                        'lat'.center(15) + ' ' +\
                        'num_dens'.center(15) + ' ' +\
                        'align'.center(15) + '\n')
g.close()
                
# Access file frames
with hoomd.open(name=inFile, mode='rb') as t:

    # Take first snap for box
    start = 600                  # first frame to process
    dumps = int(t.__len__())    # get number of timesteps dumped
    end = dumps                 # final frame to process
    snap = t[0]
    first_tstep = snap.configuration.step
    box_data = snap.configuration.box
    # Get box dimensions
    l_box = box_data[0]
    h_box = l_box / 2.
    a_box = l_box * l_box
    
    radius=np.arange(0,h_box+3.0, 3.0)
    
    NBins = getNBins(l_box, r_cut)
    sizeBin = roundUp((l_box / NBins), 6)
    partNum = len(snap.particles.typeid)
    pos = snap.particles.position
    
    # Get the largest x-position in the largest cluster
    f_box = box.Box(Lx=l_box, Ly=l_box, is2D=True)
    my_clust = cluster.Cluster()
    c_props = cluster.ClusterProperties()
    density = freud.density.LocalDensity(r_max=10., diameter=1.0)
    
    # You need a list of length nBins to hold the sum
    phi_sum = [ 0. for i in range(0, NBins) ]
    p_sum = [ 0. for i in range(0, NBins) ]
    pswim_sum = [ 0. for i in range(0, NBins) ]
    pint_sum = [ 0. for i in range(0, NBins) ]
    # You need one array of length nBins to hold the counts
    num = [ 0. for i in range(0, NBins) ]
    # You should store the max distance of each bin as well
    r_bins = np.arange(sizeBin, sizeBin * NBins, sizeBin)

    # Loop through snapshots
    for j in range(start, end):
    
        print('j')
        print(j)
        j=600
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
        
        # Compute the center of mass
        # Compute neighbor list for only largest cluster
        
        system_all = freud.AABBQuery(f_box, f_box.wrap(pos))
        
        cl_all=freud.cluster.Cluster()                      #Define cluster
        cl_all.compute(system_all, neighbors={'r_max': 1.0})    # Calculate clusters given neighbor list, positions,
                                                        # and maximal radial interaction distance
        clp_all = freud.cluster.ClusterProperties()         #Define cluster properties
        ids = cl_all.cluster_idx              # get id of each cluster
        clp_all.compute(system_all, ids)             # Calculate cluster properties given cluster IDs
        clust_size = clp_all.sizes              # find cluster sizes
        min_size=int(partNum/5)
        lcID = np.where(clust_size == np.amax(clust_size))[0][0]
        large_clust_ind_all=np.where(clust_size>min_size)

        # Only look at clusters if the size is at least 10% of the system
        if len(large_clust_ind_all[0])>0:
            
            
            
            
            rad_bins=np.zeros(len(radius))
            query_points=clp_all.centers[lcID]
            com_tmp_posX = query_points[0] + h_box
            com_tmp_posY = query_points[1] + h_box

            com_x_ind = int(com_tmp_posX / sizeBin)
            com_y_ind = int(com_tmp_posY / sizeBin)
            # Loop through each timestep
            tot_count_gas=np.zeros((end,2))
            tot_count_dense=np.zeros((end,2))
            tot_count_edge=np.zeros((end,2))
            rad_count_gas=np.zeros((end,int(NBins/2)-1,2))
            rad_count_dense=np.zeros((end,int(NBins/2)-1,2))
            rad_count_edge=np.zeros((end,int(NBins/2)-1,2))
            # Get the positions of all particles in LC
            binParts = [[[] for b in range(NBins)] for a in range(NBins)]
            typParts=  [[[] for b in range(NBins)] for a in range(NBins)]
            #posParts=  [[[] for b in range(NBins)] for a in range(NBins)]
            occParts = [[0 for b in range(NBins)] for a in range(NBins)]
            edgeBin = [[0 for b in range(NBins)] for a in range(NBins)]
            
            
            
            #Assigns particle indices and types to bins
            for k in range(0, len(ids)):

                # Convert position to be > 0 to place in list mesh
                tmp_posX = pos[k][0] + h_box
                tmp_posY = pos[k][1] + h_box
                x_ind = int(tmp_posX / sizeBin)
                y_ind = int(tmp_posY / sizeBin)
                # Append all particles to appropriate bin
                binParts[x_ind][y_ind].append(k)
                typParts[x_ind][y_ind].append(typ[k])
                #posParts[x_ind][y_ind].append(pos[k])
                
                if clust_size[ids[k]] >= min_size:
                    occParts[x_ind][y_ind] = 1
            # If sufficient neighbor bins are empty, we have an edge
            PhaseParts=np.zeros(len(pos))
            PhaseParts2=np.zeros(len(pos))
            PhasePartsarea=np.zeros(len(pos))
            gasBins = 0
            bulkBins = 0
            edgeBins=0
            edgeBinsbig = 0
            bulkBinsbig = 0
            testIDs = [[0 for b in range(NBins)] for a in range(NBins)]
            testIDs_area = [[0 for b in range(NBins)] for a in range(NBins)]

            for ix in range(0, len(occParts)):
                for iy in range(0, len(occParts)):
                    if len(binParts[ix][iy]) != 0:
                        if clust_size[ids[binParts[ix][iy][0]]] >=min_size:
                            bulkBins += 1
                            testIDs[ix][iy] = 1
                            testIDs_area[ix][iy] = 1
                            continue
                    gasBins += 1
                    testIDs[ix][iy] = 2
                    testIDs_area[ix][iy] = 2
            
            
                        
                        
            count_A_edge=0
            count_B_edge=0
            gas_particle_range=2.0
            gas_r_lim=gas_particle_range*lat
            bulk_particle_range=5.0
            end_loop=0
            steps=0
            num_sights_len=20
            num_sights=np.arange(0, 360+int(360/num_sights_len),int(360/num_sights_len))
            
            area_slice=np.zeros(len(radius)-1)
            for f in range(0,len(radius)-1):
                area_slice[f]=((num_sights[1]-num_sights[0])/360)*math.pi*(radius[f+1]**2-radius[f]**2)
            for k in range(1,len(num_sights)):
                pos_new_x=np.array([])
                pos_new_y=np.array([])
                losBin = [[0 for b in range(NBins)] for a in range(NBins)]

                for ix in range(0, len(occParts)):
                    for iy in range(0, len(occParts)):
                        x_min_ref=ix*sizeBin#+com_tmp_posX
                        x_max_ref=(ix+1)*sizeBin#+com_tmp_posX
                        y_min_ref=iy*sizeBin# +com_tmp_posY
                        y_max_ref=(iy+1)*sizeBin#+com_tmp_posY

                        dif_x_min = (x_min_ref-com_tmp_posX)
                        difx_min_abs = np.abs(dif_x_min)

                        if difx_min_abs>=h_box:
                            if dif_x_min < -h_box:
                                dif_x_min += l_box
                            else:
                                dif_x_min -= l_box
                        dif_x_max = (x_max_ref-com_tmp_posX)

                        difx_max_abs = np.abs(dif_x_max)
                        if difx_max_abs>=h_box:
                            if dif_x_max < -h_box:
                                dif_x_max += l_box
                            else:
                                dif_x_max -= l_box
                        dif_y_min = (y_min_ref-com_tmp_posY)

                        dify_min_abs = np.abs(dif_y_min)
                        if dify_min_abs>=h_box:
                            if dif_y_min < -h_box:
                                dif_y_min += l_box
                            else:
                                dif_y_min -= l_box
                        dif_y_max = (y_max_ref-com_tmp_posY)

                        dify_max_abs = np.abs(dif_y_max)
                        if dify_max_abs>=h_box:
                            if dif_y_max < -h_box:
                                dif_y_max += l_box
                            else:
                                dif_y_max -= l_box
                            
                        if ((ix!=com_x_ind) or (iy!=com_y_ind)):

                            if ((dif_x_min>=0) and (dif_x_max>=0)):
                                if ((dif_y_min>=0) and (dif_y_max>=0)):
                                    min_ref=np.array([x_min_ref, y_max_ref])
                                    min_quad=1
                                    max_ref=np.array([x_max_ref, y_min_ref])
                                    max_quad=1
                                    max_angle=(np.arctan(np.abs(dif_y_max)/np.abs(dif_x_min)))*180/np.pi+(min_quad-1)*90
                                    min_angle=(np.arctan(np.abs(dif_y_min)/np.abs(dif_x_max)))*180/np.pi+(min_quad-1)*90
                                elif ((dif_y_min<=0) and (dif_y_max<=0)):
                                    min_ref=np.array([x_min_ref, y_min_ref])
                                    min_quad=4
                                    max_ref=np.array([x_max_ref, y_max_ref])
                                    max_quad=4
                                    min_angle=(np.arctan(np.abs(dif_x_min)/np.abs(dif_y_min)))*180/np.pi+(min_quad-1)*90
                                    max_angle=(np.arctan(np.abs(dif_x_max)/np.abs(dif_y_max)))*180/np.pi+(max_quad-1)*90
                                elif (((dif_y_min<=0) and (dif_y_max>=0)) or ((dif_y_min>=0) and (dif_y_max<=0))):
                                    min_ref=np.array([x_min_ref, y_min_ref])
                                    min_quad=4
                                    max_ref=np.array([x_min_ref, y_max_ref])
                                    max_quad=1

                                    max_angle=(np.arctan(np.abs(dif_x_min)/np.abs(dif_y_min)))*180/np.pi+(min_quad-1)*90
                                    min_angle=(np.arctan(np.abs(dif_y_max)/np.abs(dif_x_min)))*180/np.pi+(max_quad-1)*90
                            elif ((dif_x_min<0) and (dif_x_max<0)):
                                if ((dif_y_min>0) and (dif_y_max>0)):
                                    min_ref=np.array([x_min_ref, y_min_ref])
                                    min_quad=2
                                    max_ref=np.array([x_max_ref, y_max_ref])
                                    max_quad=2
                                    max_angle=((np.arctan(np.abs(dif_x_min)/np.abs(dif_y_min)))*(180/np.pi))+(min_quad-1)*90
                                    min_angle=((np.arctan(np.abs(dif_x_max)/np.abs(dif_y_max)))*(180/np.pi))+(max_quad-1)*90
                                elif ((dif_y_min<0) and (dif_y_max<0)):
                                    min_ref=np.array([x_min_ref, y_max_ref])
                                    min_quad=3
                                    max_ref=np.array([x_max_ref, y_min_ref])
                                    max_quad=3
                                    min_angle=(np.arctan(np.abs(dif_y_max)/np.abs(dif_x_min)))*180/np.pi+(min_quad-1)*90
                                    max_angle=(np.arctan(np.abs(dif_y_min)/np.abs(dif_x_max)))*180/np.pi+(max_quad-1)*90
                                elif (((dif_y_min<0) and (dif_y_max>0)) or ((dif_y_min>0) and (dif_y_max<0))):
                                    min_ref=np.array([x_max_ref, y_min_ref])
                                    min_quad=3
                                    max_ref=np.array([x_max_ref, y_max_ref])
                                    max_quad=2
                                    max_angle=(np.arctan(np.abs(dif_y_min)/np.abs(dif_x_max)))*180/np.pi+(min_quad-1)*90
                                    min_angle=(np.arctan(np.abs(dif_x_max)/np.abs(dif_y_max)))*180/np.pi+(max_quad-1)*90
                            elif (((dif_x_min<0) and (dif_x_max>0)) or ((dif_x_min>0) and (dif_x_max<0))):
                                if ((dif_y_min>0) and (dif_y_max>0)):
                                    min_ref=np.array([x_min_ref, y_min_ref])
                                    min_quad=2
                                    max_ref=np.array([x_max_ref, y_min_ref])
                                    max_quad=1
                                    max_angle=(np.arctan(np.abs(dif_x_min)/np.abs(dif_y_min)))*180/np.pi+(min_quad-1)*90
                                    min_angle=(np.arctan(np.abs(dif_y_min)/np.abs(dif_x_max)))*180/np.pi+(max_quad-1)*90
                                elif ((dif_y_min<0) and (dif_y_max<0)):
                                    min_ref=np.array([x_min_ref, y_max_ref])
                                    min_quad=3
                                    max_ref=np.array([x_max_ref, y_max_ref])
                                    max_quad=4
                                    min_angle=(np.arctan(np.abs(dif_y_max)/np.abs(dif_x_min)))*180/np.pi+(min_quad-1)*90
                                    max_angle=(np.arctan(np.abs(dif_x_max)/np.abs(dif_y_max)))*180/np.pi+(max_quad-1)*90
                                elif (((dif_y_min<0) and (dif_y_max>0)) or ((dif_y_min>0) and (dif_y_max<0))):

                                    max_angle=45.1
                                    min_angle=44.9

                            #if min_angle<=
                            if min_angle<=90 and max_angle>=270:
                                if 0<=num_sights[k-1]<=min_angle:
                                    losBin[ix][iy]=1
                                elif 0<=num_sights[k]<=min_angle:
                                    losBin[ix][iy]=1
                                elif num_sights[k-1]<=min_angle<=num_sights[k-1]:
                                    losBin[ix][iy]=1
                                elif max_angle<=num_sights[k-1]<=360:
                                    losBin[ix][iy]=1
                                elif max_angle<=num_sights[k]<=360:
                                    losBin[ix][iy]=1
                                elif num_sights[k-1]<=max_angle<=num_sights[k-1]:
                                    losBin[ix][iy]=1
                            elif min_angle<=num_sights[k-1]<=max_angle:
                                losBin[ix][iy]=1
                            elif min_angle<=num_sights[k]<=max_angle:
                                losBin[ix][iy]=1
                            elif num_sights[k-1]<=min_angle<=num_sights[k]:
                                losBin[ix][iy]=1
                            elif num_sights[k-1]<=max_angle<=num_sights[k]:
                                losBin[ix][iy]=1
                                    
                            
                        elif ((ix==com_x_ind) and (iy==com_y_ind)):
                            losBin[ix][iy]=1

                rad_bin=np.zeros(len(radius)-1)
                align_rad=np.zeros(len(radius)-1)
                pressure_vp = np.zeros(len(radius)-1)
                press_num = np.zeros(len(radius)-1)
                lat_space = np.zeros(len(radius)-1)
                for ix in range(0, len(occParts)):
                    for iy in range(0, len(occParts)):
                        if losBin[ix][iy]==1:
                            if len(binParts[ix][iy])!=0:
                                
                                for h in range(0,len(binParts[ix][iy])):
                                    x_pos=pos[binParts[ix][iy]][h][0]+h_box
                                        
                                    y_pos=pos[binParts[ix][iy]][h][1]+h_box
                                        
                                    difx=x_pos-com_tmp_posX
                                    difx_abs = np.abs(difx)
                                    if difx_abs>=h_box:
                                        if difx < -h_box:
                                            difx += l_box
                                        else:
                                            difx -= l_box
                                    dify=y_pos-com_tmp_posY
                                    dify_abs = np.abs(dify)
                                    if dify_abs>=h_box:
                                        if dify < -h_box:
                                            dify += l_box
                                        else:
                                            dify -= l_box

                                    if (difx)>0:
                                        if (dify)>0:
                                            part_quad=1
                                            part_angle=(np.arctan(np.abs(dify)/np.abs(difx)))*180/np.pi+(part_quad-1)*90
                                        elif (dify)<0:
                                            part_quad=4
                                            part_angle=(np.arctan(np.abs(difx)/np.abs(dify)))*180/np.pi+(part_quad-1)*90
                                        elif (dify)==0:
                                            part_angle=0
                                    elif (difx)<0:
                                        if (dify)>0:
                                            part_quad=2
                                            part_angle=(np.arctan(np.abs(difx)/np.abs(dify)))*180/np.pi+(part_quad-1)*90
                                        elif (dify)<0:
                                            part_quad=3
                                            part_angle=(np.arctan(np.abs(dify)/np.abs(difx)))*180/np.pi+(part_quad-1)*90
                                        elif (dify)==0:
                                            part_angle=180
                                    elif (difx)==0:
                                        if (dify)>0:
                                            part_angle=90
                                        elif (dify)<0:
                                            part_angle=270
                                        elif (dify)==0:
                                            part_angle=(num_sights[k]+num_sights[k-1])/2
                                    if num_sights[k-1]<=part_angle<=num_sights[k]:

                                        pos_new_x=np.append(pos_new_x, x_pos)
                                        pos_new_y=np.append(pos_new_y, y_pos)
                                        
                                        difr=(difx**2+dify**2)**0.5

                                        for l in range(1,len(radius)):
                                            if radius[l-1]<=difr<=radius[l]:
                                                rad_bin[l-1]+=1
                                                
                                                
                                                if ix==0:
                                                    ix_new_range = [len(occParts)-1, 0, 1]
                                                elif ix==len(occParts)-1:
                                                    ix_new_range = [len(occParts)-2, len(occParts)-1, 0]
                                                else:
                                                    ix_new_range = [ix-1, ix, ix+1]
                                                
                                                if iy==0:
                                                    iy_new_range = [len(occParts)-1, 0, 1]
                                                elif iy==len(occParts)-1:
                                                    iy_new_range = [len(occParts)-2, len(occParts)-1, 0]
                                                else:
                                                    iy_new_range = [iy-1, iy, iy+1]
                                                for ix2 in ix_new_range:
                                                    for iy2 in iy_new_range:
                                                        if len(binParts[ix2][iy2])!=0:
                                
                                                            for h2 in range(0,len(binParts[ix2][iy2])):
                                                                if binParts[ix2][iy2][h2] != binParts[ix][iy][h]:
                                                                    x_pos_new=pos[binParts[ix2][iy2]][h2][0]+h_box
                                            
                                                                    y_pos_new=pos[binParts[ix2][iy2]][h2][1]+h_box
                                            
                                                                    difx2=x_pos-x_pos_new
                                                                    difx_abs2 = np.abs(difx2)
                                                                    if difx_abs2>=h_box:
                                                                        if difx2 < -h_box:
                                                                            difx2 += l_box
                                                                        else:
                                                                            difx2 -= l_box
                                                                    dify2=y_pos-y_pos_new
                                                                    dify_abs2 = np.abs(dify2)
                                                                    if dify_abs2>=h_box:
                                                                        if dify2 < -h_box:
                                                                            dify2 += l_box
                                                                        else:
                                                                            dify2 -= l_box
                                                                    
                                                                    difr2=(difx2**2+dify2**2)**0.5
                                                                    
                                                                    if 0.001<=difr2<=r_cut:
                                                                        fx, fy = computeFLJ(difr2, difx2, dify2, eps)
                                                                        # Compute the x force times x distance
                                                                        sigx = fx * (difx2)
                                                                        # Likewise for y
                                                                        sigy = fy * (dify2)
                                                                        press_num[l-1] += 1
                                                                        pressure_vp[l-1] += ((sigx + sigy)/2)
                                                                        lat_space[l-1] += difr2
                                                                
                                                                
                                                                
                                                              
                                                px = np.sin(ang[binParts[ix][iy][h]])
                                                px = np.sin(ang[binParts[ix][iy][h]])
                                                py = -np.cos(ang[binParts[ix][iy][h]])
                                                
                                                
                                                
                                                r_dot_p = (-difx * px) + (-dify * py)
                                                align=r_dot_p/difr

                                                align_rad[l-1]+=align
                                                
                                #plt.figure()          
                #plt.scatter(pos_new_x-com_tmp_posX, pos_new_y-com_tmp_posY, c='b', s=1)   
                #plt.scatter(0, 0, c='r', s=5)  
                #plt.ylim((-h_box, 10.0))
                #plt.xlim((-10.0, 10.0))
                #plt.draw()
                #plt.pause(0.1)
                #stop
                #plt.pause(0.1)
                                #plt.close()
                                
                                                
                num_dens=np.zeros(len(radius)-1)
                align_tot=np.zeros(len(radius)-1)
                lat_space_avg=np.zeros(len(radius)-1)
                pressure_vp_avg=np.zeros(len(radius)-1)
                for f in range(0, len(align_rad)):
                    if rad_bin[f]!=0:
                        align_tot[f]=(align_rad[f]/rad_bin[f])
                for f in range(0, len(radius)-1):
                    num_dens[f]=rad_bin[f]/area_slice[f]
                for f in range(0, len(lat_space_avg)):
                    if rad_bin[f]!=0:
                        lat_space_avg[f]=(lat_space[f]/rad_bin[f]) 
                for f in range(0, len(pressure_vp)):
                    pressure_vp_avg[f]=(pressure_vp[f]/area_slice[f]) 

                
                g = open(outTxt, 'a')
                for h in range(0, len(rad_bin)):
                    g.write('{0:.2f}'.format(tst).center(15) + ' ')
                    g.write('{0:.0f}'.format(np.amax(clust_size)).center(15) + ' ')
                    g.write('{0:.1f}'.format(num_sights[k-1]).center(15) + ' ')
                    g.write('{0:.1f}'.format(num_sights[k]).center(15) + ' ')
                    g.write('{0:.6f}'.format(radius[h+1]).center(15) + ' ')
                    g.write('{0:.1f}'.format(rad_bin[h]).center(15) + ' ')
                    g.write('{0:.6f}'.format(pressure_vp_avg[h]/2).center(15) + ' ')
                    g.write('{0:.6f}'.format(lat_space_avg[h]).center(15) + ' ')
                    g.write('{0:.6f}'.format(num_dens[h]).center(15) + ' ')
                    g.write('{0:.6f}'.format(align_tot[h]).center(15) + '\n')
                g.close()
            