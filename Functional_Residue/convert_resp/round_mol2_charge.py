import sys
import math
# Mol2ファイルの読み込み

name=sys.argv[1]


with open(f"./{name}/{name}.mol2", "r") as f:
    lines = f.readlines()

# 電荷の丸め込みと合計の算出
sum_charge = 0.0
charges = []
atom_types = []
for i, line in enumerate(lines):
    if line.startswith("@<TRIPOS>ATOM"):
        for l in lines[i+1:]:
            if l.startswith("@<TRIPOS>"):
                break
            charges.append(round(float(l.split()[8]), 5))
            atom_types.append(l.split()[1])

print(f"Rounded charges: {charges}")
sum_charge = sum(charges)

# 電荷の整数部分の算出

# 電荷の差分の算出と適用
diff_charge = round(int(sum_charge) - sum_charge, 5)
print(diff_charge, int(sum_charge), sum_charge)
mod_charge_atom_index = -1
for index, at in enumerate(atom_types):
    if "H" in at:
        continue
    else:
        mod_charge_atom_index = index
        
# 適当な原子に電荷を加える
charges[mod_charge_atom_index] += diff_charge
print(f"Modified charges: {charges}")

# 電荷の合計の再算出
sum_charge = sum(charges)

# 調整した結果の出力
print("sum_charge: ", round(sum_charge, 5))
is_atom = False
atom_index = 0
with open((f"./{name}/{name}.mol2").replace(".mol2", "_round.mol2"), "w") as f:
    for i, line in enumerate(lines):
        if line.startswith("@<TRIPOS>ATOM"):
            is_atom = True
            f.write(line)
            continue
        if line.startswith("@<TRIPOS>"):
            is_atom = False
            f.write(line)
            continue
        if is_atom == True:
            fixed_line=(f'{line[:72]}{round(charges[atom_index], 5):8.5f}\n')
            f.write(fixed_line)
            atom_index += 1
            continue
        f.write(line)

