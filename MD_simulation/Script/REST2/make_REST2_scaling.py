#! /usr/bin/env python3
import math, os, glob, subprocess, sys
import numpy as np
 
GMX_MPI="/work/LSC/y4su_da/software/gmxgpu-2022/bin/gmx_mpi"

if(len(sys.argv) <= 1):
    print('./make_REST2_scaling.py $nreplica $tmin $tmax')
    sys.exit()

nrep = int(sys.argv[1])
tmin = int(sys.argv[2])
tmax = int(sys.argv[3])
 
temp_list = [ tmin * math.exp(i * math.log( tmax / tmin ) / ( nrep - 1 )) for i in range( nrep )]
lambda_list = [ temp_list[0] / temp_list[i] for i in range( nrep )]
print("temperature :", temp_list)
print("lambda :", lambda_list)
np.savetxt("temp.txt",np.array(temp_list))
np.savetxt("lambda.txt",np.array(lambda_list))
 

files = glob.glob( "./#*" )
files += glob.glob( "./topol*" )
 
for f in files:
    os.remove( f )
 
for i in range( nrep ):

    lambdavalue = lambda_list[i] 

    command1 = f"mkdir replica{i}"
    subprocess.call( command1, shell=True )
  
    command2 = f"./make_REST2_top.sh {i} {lambdavalue}"
    subprocess.call( command2, shell=True  )
 
    command3 = f"{GMX_MPI} grompp -maxwarn 1 -o replica{i}/hrex.tpr -f hrex.mdp -c ./input/npt.gro -p replica{i}/topol_REST2_{i}.top -r ./input/em.gro"
    subprocess.call( command3, shell=True )
    
    command4 = f"touch replica{i}/hrex.dat"
    subprocess.call( command4, shell=True )

os.remove("./make_REST2_top.py")
os.remove("mdout.mdp")
