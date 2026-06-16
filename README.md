# asap7-synthesis-rv12-eth_top

Frequency sweep synthesis (500/600/700 MHz) on RV12 RISC-V CPU and Ethernet MAC using OpenLane + ASAP7 7nm PDK.

---

## ORFS Fresh Machine Setup (one-time, repeatable on any PC)

### 0. Prerequisites

- Ubuntu 20.04/22.04 (or equivalent)
- `sudo` access
- ~20GB free disk (image + PDKs + build artifacts)

### 1. Install Docker + git (skip if already present)

```bash
sudo apt-get update
sudo apt-get install -y docker.io git
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
# log out and back in for group change to take effect
```

### 2. Pull image and clone repo (can run in parallel, two terminals)

```bash
docker pull openroad/orfs

cd /mnt/openlane_disk        # or wherever you keep projects
git clone --recursive https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts.git ORFS
```

### 3. Create ONE persistent named container, flow/ bind-mounted

```bash
cd /mnt/openlane_disk/ORFS
docker run -dit \
  --name orfs_main \
  -v $(pwd)/flow:/OpenROAD-flow-scripts/flow \
  openroad/orfs
```

### 4. Enter container, make env auto-load every future exec

```bash
docker exec -it orfs_main bash
source /OpenROAD-flow-scripts/env.sh
openroad -version     # sanity check, should print a version string
yosys -V               # sanity check
echo "source /OpenROAD-flow-scripts/env.sh" >> ~/.bashrc
```

### 5. Fetch every PDK you'll need — once, ever, per container

```bash
cd /OpenROAD-flow-scripts/flow
make sky130hd
make asap7
make gf180
# add any other platform the same way:
# make <platform_name>
```

### 6. Verify the full toolchain end-to-end (don't skip)

```bash
make DESIGN_CONFIG=./designs/sky130hd/gcd/config.mk
make DESIGN_CONFIG=./designs/asap7/gcd/config.mk
```

> Both must finish clean ("Generated GDS" / no ERROR lines) before trusting this setup for real designs.

---

## Setup is now done

For every new PC: repeat steps 1–6 identically.

For every new design from here on, you only need:

```bash
docker exec -it orfs_main bash
cd /OpenROAD-flow-scripts/flow
make DESIGN_CONFIG=./designs/<platform>/<your_design>/config.mk
```
