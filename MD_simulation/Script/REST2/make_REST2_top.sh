#!/bin/bash


rm ./*#
rm ./processed_fixed.top
rm ./processed.top

index=$1
scale=$2

#processed.topの作成
/work/LSC/y4su_da/software/gmxgpu-2022/bin/gmx_mpi grompp -f ./input/min.mdp -c ./input/npt.gro -p ./input/model.top -pp -r ./input/em.gro

#スケーリングする分子にアンダーバーを付加
cat << eof0 > ./make_REST2_top.py
resname_list=["GLY","ALA","SER","THR","CYS","ASN","GLN","LEU","ILE","VAL","MET","PHE","TYR","TRP","PRO","ASP","GLU","HIS","LYS","ARG", "HIE", "HID", "NME", "ACE"]
input_data=[]
with open(f"processed.top") as f:
    for line in f:
        if len(line.split())==11 and line.split()[3] in resname_list and line.split()[0]!=";":
            new_line = line.split()
            new_line[1] = new_line[1] + "_"
            input_data.append(" ".join(new_line)+"\n")
        else:
            input_data.append(line)
with open(f"processed_fixed.top","w") as f:
    for line in (input_data):
        f.write(line)
eof0

python make_REST2_top.py

#スケーリングファクターの設定
./partial_tempering.sh $scale < processed_fixed.top > ./topol_REST2_${index}.top
mv ./topol_REST2_${index}.top ./replica${index}

#hrex_inputの作成
cat << eof1 > ./hrex.mdp
; Run parameters
integrator              = md        ; leap-frog integrator
nsteps                  = 125000000 ; 2 * 125000000 = 250 ns
dt                      = 0.002     ; 2 fs
; Output control
nstxout                 = 0       ; save coordinates every 1.0 ps
nstvout                 = 0       ; save velocities every 1.0 ps
nstenergy               = 12500       ; save energies every 1.0 ps
nstlog                  = 12500       ; update log file every 10.0 ps
nstxout-compressed  = 12500 
; Bond parameters
continuation            = yes       ; Restarting after NVT 
constraint_algorithm    = lincs     ; holonomic constraints 
constraints             = h-bonds   ; bonds involving H are constrained
lincs_iter              = 1         ; accuracy of LINCS
lincs_order             = 4         ; also related to accuracy
; Nonbonded settings 
cutoff-scheme           = Verlet    ; Buffered neighbor searching
ns_type                 = grid      ; search neighboring grid cells
nstlist                 = 10        ; 20 fs, largely irrelevant with Verlet scheme
rcoulomb                = 1.0       ; short-range electrostatic cutoff (in nm)
rvdw                    = 1.0       ; short-range van der Waals cutoff (in nm)
DispCorr                = EnerPres  ; account for cut-off vdW scheme
; Electrostatics
coulombtype             = PME       ; Particle Mesh Ewald for long-range electrostatics
pme_order               = 4         ; cubic interpolation
fourierspacing          = 0.16      ; grid spacing for FFT
; Temperature coupling is on
tcoupl                  = V-rescale             ; modified Berendsen thermostat
tc-grps                 = Non-Water Water   ; two coupling groups - more accurate
tau_t                   = 0.1       0.1           ; time constant, in ps
ref_t                   = 300       300           ; reference temperature, one for each group, in K
; Pressure coupling is on
pcoupl                  = C-rescale     ; Pressure coupling on in NPT
pcoupltype              = isotropic             ; uniform scaling of box vectors
tau_p                   = 2.0                   ; time constant, in ps
ref_p                   = 1.0                   ; reference pressure, in bar
compressibility         = 4.5e-5                ; isothermal compressibility of water, bar^-1
refcoord_scaling        = com
; Periodic boundary conditions
pbc                     = xyz       ; 3-D PBC
; Velocity generation
gen_vel                 = no        ; Velocity generation is off
eof1

rm ./*#
rm ./processed_fixed.top
rm ./processed.top
