#!/bin/bash

RUNID="$(cat /dev/urandom | base64 | tr -dc "A-Z" | fold -w 5 | head -n 1)"
HOMEDIR=$(pwd)
nrep=$1
GMX_MPI=/work/LSC/y4su_da/software/gmxgpu-2022/bin/gmx_mpi
OMP_NUM_THREADS=24
OMP=24
MODULE=gdr/3.1.6/intel19.0.5-cuda10.2

  cat << eof0 > ./qsub.sh
#!/bin/bash
#------- qsub option -----------
#PBS -A LSC
#PBS -q gpu
#PBS -N RIB_model_REST2
#PBS -l elapstim_req=24:00:00
#PBS -b $nrep
#PBS -T openmpi
#PBS -v NQSV_MPI_VER=$MODULE
#PBS -v LD_LIBRARY_PATH=$LD_LIBRARY_PATH
#------- Program execution -----------
module clear << eof1
y
eof1

module load openmpi/$MODULE
cd $HOMEDIR

mpirun \${NQSII_MPIOPTS} -np $nrep -npernode 1 --bind-to none $GMX_MPI mdrun -deffnm hrex -ntomp $OMP -multidir replica{0..$(($nrep-1))} -replex 1000 -hrex -plumed hrex.dat 
eof0

qsub qsub.sh
