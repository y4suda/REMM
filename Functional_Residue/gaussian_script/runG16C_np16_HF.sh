#!/bin/csh
#PBS -q np16
#PBS -l nodes=1:ppn=16
#PBS -o result.out
#PBS -e result.err
#PBS -N G16C

#---------------------- setting -------------------------#
setenv GAUSS_SCRDIR ${PBS_O_WORKDIR}
setenv g16root ~physbio/bin/g16C
setenv GAUSS_MEMDEF 124000000
setenv PATH "${PATH}:${g16root}"

#
#if (! -e "$GAUSS_SCRDIR") then
#  mkdir $GAUSS_SCRDIR
#else
#  rm -rf $GAUSS_SCRDIR/*
#endif

if ( -e $g16root/g16/bsd/g16.login ) then
  source $g16root/g16/bsd/g16.login
endif

set gaussian = ${g16root}/g16/g16
set gInp = 'HF.gjf'



# # # # # # # # # # # # # # # # # # # # # # # #
set num = ${PBS_JOBID}
set workDir = ${PBS_O_WORKDIR}
set NPROCS = `wc -l < $PBS_NODEFILE`

cd ${PBS_O_WORKDIR}

cat $PBS_NODEFILE > hostfile

# # # # # # # # # # # # # # # # # # # # # # # #
:>  $num.log
#echo ' PBS JobID: '$PBS_JOBID >> $num.log
echo ' Node Num    :'$NPROCS >> $num.log
echo ' Nodes     : '`head -1 $PBS_NODEFILE` >> $num.log
#cat $PBS_NODEFILE    >> $num.log
echo ' SubmitDir : '$PBS_O_WORKDIR >> $num.log
echo ' WorkingDir: '$workDir >> $num.log
echo ' OutputFile: '$workDir/stdout >> $num.log
echo '  G16 < inp.nw > stdout' >> $num.log
date +'  Start  20'%y%m%d' '%H%M%S     >>  $num.log

# # # PostProcess
:>  $num.ppr
echo "export num=$num" >> $num.ppr
echo " cd $workDir" >> $num.ppr
echo " date +'  End    20'%y%m%d' '%H%M%S     >>  $num.log" >> $num.ppr
echo "mv ${num}.log ${num}.loged" >> $num.ppr
#echo "rm -rf $GAUSS_SCRDIR/*" >> $num.ppr
echo "rm $num.ppr" >> $num.ppr

chmod +x $num.ppr

# check %NProcsection
set checkShell = /home/physbio/bin/check_GaussianInput_NProc_Linda.py
if ( -e ${checkShell} ) then
  ${checkShell} ${gInp} npp=$NPROCS GV=16 hostfile=hostfile
endif
#
# # # # # # # # # # # # # # # # # # # # # # # #
#mpirun -hostfile ${PBS_NODEFILE} -mca pls_rsh_agent rsh -np 320 nwchem ./inp.nw
#(nohup time ${gaussian} < inp.com > stdout ) >& errout
(nohup time ${gaussian} < ${gInp} >& HF.log )


./$num.ppr


