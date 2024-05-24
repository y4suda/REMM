#!/bin/bash
#------- qsub option -----------
#PBS -A LSC
#PBS -q gpu
#PBS -N SOL_7o1a_REST2
#PBS -l elapstim_req=24:00:00
#PBS -b 8
#PBS -T openmpi
#PBS -v NQSV_MPI_VER=gdr/3.1.6/intel19.0.5-cuda10.2
#PBS -v LD_LIBRARY_PATH=/work/LSC/ryuhei/opt/intel/mkl/9.1/lib/em64t:/work/LSC/ryuhei/software/gmxgpu-2019.6/lib64:/system/apps/intel/2019update5/compilers_and_libraries_2019.5.281/linux/compiler/lib/intel64_lin:/system/apps/intel/2019update5/compilers_and_libraries_2019.5.281/linux/ipp/lib/intel64:/system/apps/intel/2019update5/compilers_and_libraries_2019.5.281/linux/compiler/lib/intel64_lin:/system/apps/intel/2019update5/compilers_and_libraries_2019.5.281/linux/mkl/lib/intel64_lin:/system/apps/intel/2019update5/compilers_and_libraries_2019.5.281/linux/tbb/lib/intel64/gcc4.7:/system/apps/intel/2019update5/compilers_and_libraries_2019.5.281/linux/tbb/lib/intel64/gcc4.7:/system/apps/intel/2019update5/debugger_2019/libipt/intel64/lib:/system/apps/intel/2019update5/compilers_and_libraries_2019.5.281/linux/daal/lib/intel64_lin:/system/apps/intel/2019update5/compilers_and_libraries_2019.5.281/linux/daal/../tbb/lib/intel64_lin/gcc4.4:/system/apps/rhel79_2023/cuda/10.2/lib64:/work/LSC/ryuhei/software/openmpi-3.0.6/lib:/work/LSC/y4su_da/software/lib:/usr/lib64/cmake3/:/work/LSC/y4su_da/software/NAMD_2.14_Linux-x86_64-multicore-CUDA:/work/LSC/y4su_da/software/plumed/2.8/lib
#------- Program execution -----------
module clear << eof1
y
eof1

module load openmpi/gdr/3.1.6/intel19.0.5-cuda10.2
cd /work/LSC/y4su_da/CTF_inCNT/v5.0/D24_L5_7o1a/REST2/tri1

mpirun ${NQSII_MPIOPTS} -np 8 -npernode 1 --bind-to none /work/LSC/y4su_da/software/gmxgpu-2022/bin/gmx_mpi mdrun -deffnm hrex -ntomp 24 -multidir replica{0..7} -replex 1000 -hrex -plumed hrex.dat 
