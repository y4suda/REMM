#!/bin/bash


name=$1
charge=$2

cd $name

antechamber -i HF.log -fi gout -o ${name}.mol2 -fo mol2 -c resp -nc ${charge} -m 1 -rn ${name} -at gaff2
read -p "Modify mol2 file, then hit enter: "

cd ..
python round_mol2_charge.py ${name}

cd $name

parmchk2 -i ${name}.mol2 -f mol2 -o ${name}.frcmod

cat << EOF > leap.in
source leaprc.protein.ff14SB
source leaprc.gaff2
${name} = loadmol2 ${name}_round.mol2
loadamberparams ${name}.frcmod
saveoff ${name} ${name}.lib

quit
EOF

tleap -f leap.in

