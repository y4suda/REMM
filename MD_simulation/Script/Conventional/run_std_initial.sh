#!/bin/sh


name=model
GMX_MPI=/work/LSC/y4su_da/software/gmxgpu-2022/bin/gmx_mpi
OMP=24

rm -r ./\#*\#

########################################
# Make input files
########################################

$GMX_MPI make_ndx -f ${name}.gro << eof
q
eof

########################################
# Energy minimization
########################################
echo "########################################"
echo "Start energy minimization."
echo "########################################"

##########
# Define .mdp file
##########
echo "########################################"
echo "Make .mdp file for energy minimization for all atoms."
echo "########################################"
cat << eof0 > ./min.mdp
; minim.mdp - used as input into grompp to generate em.tpr
integrator	= steep		; Algorithm (steep = steepest descent minimization)
emtol		= 1000.0  	; Stop minimization when the maximum force < 1000.0 kJ/mol/nm
emstep      = 0.01      ; Energy step size
nsteps		= 10000	  	; Maximum number of (minimization) steps to perform

; Parameters describing how to find the neighbors of each atom and how to calculate the interactions
nstlist		    = 1		    ; Frequency to update the neighbor list and long range forces
cutoff-scheme   = Verlet
ns_type		    = grid		; Method to determine neighbor list (simple, grid)
coulombtype	    = PME		; Treatment of long range electrostatic interactions
rcoulomb	    = 1.0		; Short-range electrostatic cut-off
rvdw		    = 1.0		; Short-range Van der Waals cut-off
pbc		        = xyz 		; Periodic Boundary Conditions (yes/no)
eof0

##########
# 
##########

$GMX_MPI grompp -f ./min.mdp -c ./${name}.gro -p ./${name}.top -o ./em.tpr -n  -r model.gro
$GMX_MPI mdrun -v -deffnm ./em

##########
# Check
##########
if [ -e ./em.gro ]; then
    echo "Energy minimization has done. (lambda_state = $i)"
else
    echo "ERROR on Energy minimization"
    exit 1
fi


########################################
# NVT Equilibration
########################################
echo "########################################"
echo "Start NVT Equilibration."
echo "########################################"

##########
# Define .mdp file
##########
echo "########################################"
echo "Make .mdp file for NVT Equilibration."
echo "########################################"


cat << eof1 > nvt.mdp
title		= $name NVT equilibration 
; Run parameters
integrator	= md		; leap-frog integrator
nsteps		= 50000		; 2 * 50000 = 100 ps
dt		    = 0.002		; 2 fs
; Output control
nstxout		= 500		; save coordinates every 1.0 ps
nstvout		= 500		; save velocities every 1.0 ps
nstenergy	= 500		; save energies every 1.0 ps
nstlog		= 500		; update log file every 1.0 ps
nstxout-compressed  = 500
; Bond parameters
continuation	        = no		; first dynamics run
constraint_algorithm    = lincs	    ; holonomic constraints 
constraints	            = H-bonds	; all bonds (even heavy atom-H bonds) constrained
lincs_iter	            = 1		    ; accuracy of LINCS
lincs_order	            = 4		    ; also related to accuracy
; Neighborsearching
cutoff-scheme   = Verlet
ns_type		    = grid		; search neighboring grid cells
nstlist		    = 10		; 20 fs, largely irrelevant with Verlet
rcoulomb	    = 1.0		; short-range electrostatic cutoff (in nm)
rvdw		    = 1.0		; short-range van der Waals cutoff (in nm)
; Electrostatics
coulombtype	    = PME	; Particle Mesh Ewald for long-range electrostatics
pme_order	    = 4		; cubic interpolation
fourierspacing	= 0.16	; grid spacing for FFT
; Temperature coupling is on
tcoupl		= V-rescale	            ; modified Berendsen thermostat
tc-grps		= System           	; two coupling groups - more accurate
tau_t		= 0.1	                ; time constant, in ps
ref_t		= 300                   ; reference temperature, one for each group, in K
; Pressure coupling is off
pcoupl		= no 		; no pressure coupling in NVT
; Periodic boundary conditions
pbc		= xyz		    ; 3-D PBC
; Dispersion correction
DispCorr	= EnerPres	; account for cut-off vdW scheme
; Velocity generation
gen_vel		= yes		; assign velocities from Maxwell distribution
gen_temp	= 300		; temperature for Maxwell distribution
gen_seed	= -1		; generate a random seed
eof1


$GMX_MPI grompp -f nvt.mdp -c ./em.gro -p ./$name.top -o nvt.tpr -r ./em.gro -n ./index.ndx
$GMX_MPI mdrun -deffnm nvt -ntomp ${OMP} -v -cpo nvt.cpt

##########
# Check
##########
if [ -e ./nvt.tpr ]; then
    echo "NVT Equilibration has done."
else
    echo "ERROR on NVT Equilibration"
    exit 1
fi


########################################
# NPT Equilibrations
########################################
echo "########################################"
echo "Start NPT Equilibrations."
echo "########################################"

##########
# Define .mdp file
##########
echo "########################################"
echo "Make .mdp file for NPT Equilibrations."
echo "########################################"

cat << eof2 > ./npt.mdp
title		= $name NPT equilibration
; Run parameters
integrator	= md		; leap-frog integrator
nsteps		= 50000		; 2 * 50000 = 100 ps
dt		    = 0.002		; 2 fs
; Output control
nstxout		= 500		; save coordinates every 1.0 ps
nstvout		= 500		; save velocities every 1.0 ps
nstenergy	= 500		; save energies every 1.0 ps
nstlog		= 500		; update log file every 1.0 ps
nstxout-compressed  = 500
; Bond parameters
continuation	        = yes		; Restarting after NVT 
constraint_algorithm    = lincs	    ; holonomic constraints 
constraints	            = H-bonds	; all bonds (even heavy atom-H bonds) constrained
lincs_iter	            = 1		    ; accuracy of LINCS
lincs_order	            = 4		    ; also related to accuracy
; Neighborsearching
cutoff-scheme   = Verlet
ns_type		    = grid		; search neighboring grid cells
nstlist		    = 10	    ; 20 fs, largely irrelevant with Verlet scheme
rcoulomb	    = 1.0		; short-range electrostatic cutoff (in nm)
rvdw		    = 1.0		; short-range van der Waals cutoff (in nm)
; Electrostatics
coulombtype	    = PME		; Particle Mesh Ewald for long-range electrostatics
pme_order	    = 4		    ; cubic interpolation
fourierspacing	= 0.16		; grid spacing for FFT
; Temperature coupling is on
tcoupl		= V-rescale	            ; modified Berendsen thermostat
tc-grps		= System	; two coupling groups - more accurate
tau_t		= 0.1	 	        ; time constant, in ps
ref_t		= 300    	        ; reference temperature, one for each group, in K
; Pressure coupling is on
pcoupl		        = C-rescale	    ; Pressure coupling on in NPT
pcoupltype	        = isotropic	            ; uniform scaling of box vectors
tau_p		        = 2.0	            ; time constant, in ps
ref_p		        = 1.0 1.0		            ; reference pressure, in bar
compressibility     = 4.5e-5 4.5e-5	            ; isothermal compressibility of water, bar^-1
refcoord_scaling    = com
; Periodic boundary conditions
pbc		= xyz		; 3-D PBC
; Dispersion correction
DispCorr	= EnerPres	; account for cut-off vdW scheme
; Velocity generation
gen_vel		= no		; Velocity generation is off 

eof2


##########
# 
##########
$GMX_MPI grompp -f npt.mdp -c nvt.gro -t nvt.cpt -p ${name}.top -o npt.tpr -r em.gro -n ./index.ndx
$GMX_MPI mdrun -deffnm npt -ntomp ${OMP} -v -cpo npt.cpt


##########
# Check
##########
if [ -e ./npt.cpt ]; then
    echo "NPT Equilibration has done."
else
    echo "ERROR on NPT Equilibrations"
    exit 1
fi
