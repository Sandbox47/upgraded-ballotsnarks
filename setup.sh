#!/bin/bash

set -e 
set -u

echo "=== Starting installation ==="

# Variables
INSTALL_DIR="$(pwd)"
CIRCOM_REPO="https://github.com/iden3/circom.git"
SAGEMATH_REPO="https://github.com/sagemath/sage.git"

# --- GIT INSTALLATION ---
if ! command -v git &> /dev/null; then
    echo "Git not found. Installing git..."
    sudo apt install -y git-all
else
    echo "Git already installed."
fi

# --- INSTALL CIRCOM DEPENDENCIES ---
echo "Installing Circom dependencies..."
curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh -s -- -y
source "$HOME/.cargo/env"
sudo apt install -y npm nodejs cargo

# --- CLONE & BUILD CIRCOM ---
echo "Cloning and building Circom..."
cd "$INSTALL_DIR"
git clone "$CIRCOM_REPO"
cd circom
cargo build --release
cargo install --path circom

# --- UPDATE PATH FOR CIRCOM ---
echo "Adding Circom to PATH..."
export PATH="$HOME/.cargo/bin:$PATH"
echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$HOME/.bashrc"

# --- INSTALL C++ WITNESS DEPENDENCIES ---
echo "Installing C++ witness dependencies..."
sudo apt install -y nlohmann-json3-dev libgmp-dev nasm

# --- INSTALL snarkjs ---
echo "Installing snarkjs..."
sudo npm install -g snarkjs

# --- INSTALL SAGEMATH DEPENDENCIES ---
echo "Installing SageMath dependencies..."
sudo apt install -y automake bc binutils bzip2 ca-certificates cliquer cmake curl ecl eclib-tools \
fflas-ffpack flintqs g++ gengetopt gfan gfortran git glpk-utils gmp-ecm lcalc libatomic-ops-dev \
libboost-dev libbraiding-dev libbz2-dev libcdd-dev libcdd-tools libcliquer-dev libcurl4-openssl-dev \
libec-dev libecm-dev libffi-dev libflint-dev libfreetype-dev libgc-dev libgd-dev libgf2x-dev libgiac-dev \
libgivaro-dev libglpk-dev libgmp-dev libgsl-dev libhomfly-dev libiml-dev liblfunction-dev liblrcalc-dev \
liblzma-dev libm4rie-dev libmpc-dev libmpfi-dev libmpfr-dev libncurses-dev libntl-dev libopenblas-dev \
libpari-dev libpcre3-dev libplanarity-dev libppl-dev libprimesieve-dev libpython3-dev libqhull-dev \
libreadline-dev librw-dev libsingular4-dev libsqlite3-dev libssl-dev libsuitesparse-dev libsymmetrica2-dev \
zlib1g-dev libzmq3-dev libzn-poly-dev m4 make nauty openssl palp pari-doc pari-elldata pari-galdata \
pari-galpol pari-gp2c pari-seadata patch perl pkg-config planarity ppl-dev python3-setuptools python3-venv \
r-base-dev r-cran-lattice singular sqlite3 sympow tachyon tar tox xcas xz-utils

echo "Installing SageMath optional dependencies..."
sudo apt install -y texlive-latex-extra texlive-xetex latexmk pandoc dvipng \
4ti2 gpgconf openssh-client default-jdk libavdevice-dev coinor-cbc coinor-libcbc-dev ffmpeg \
fonts-freefont-otf fricas libigraph-dev imagemagick libisl-dev libgraphviz-dev libnauty-dev \
lrslib libtbb-dev pdf2svg libxml-libxslt-perl libxml-writer-perl libxml2-dev libperl-dev \
libfile-slurp-perl libjson-perl libsvg-perl libterm-readkey-perl libterm-readline-gnu-perl \
libmongodb-perl polymake libpolymake-dev sbcl texlive-luatex xindy

# --- CLONE & BUILD SAGEMATH ---
echo "Cloning and building SageMath (this may take several hours)..."
cd "$INSTALL_DIR"
git clone --branch master "$SAGEMATH_REPO"
cd sage
make configure
./configure
MAKE="make -j8" make

# --- LINK SAGEMATH ---
echo "Linking SageMath to /usr/local/bin..."
sudo ln -sf "$(pwd)/sage" /usr/local/bin/sage

# --- ADD CUSTOM PATHS ---
echo "Adding repository scripts to PATH and PYTHONPATH..."
echo "export PATH=\"$INSTALL_DIR/src/scripts:$INSTALL_DIR/src/scripts/snarkjs:\$PATH\"" >> "$HOME/.bashrc"
echo "export PYTHONPATH=\"$INSTALL_DIR/src/scripts:\$PYTHONPATH\"" >> "$HOME/.bashrc"

# --- CLEAN PATH DUPLICATES ---
echo "Adding path cleaning function..."
cat << 'EOF' >> "$HOME/.bashrc"

# Remove duplicate entries from PATH and PYTHONPATH
clean_path() {
    export PATH=$(echo "$PATH" | awk -v RS=: '!a[$1]++' | paste -sd:)
    export PYTHONPATH=$(echo "$PYTHONPATH" | awk -v RS=: '!a[$1]++' | paste -sd:)
}
clean_path
EOF

echo "=== Installation complete ==="
echo "Please RESTART your terminal or run 'source ~/.bashrc' to apply PATH changes."
echo "If you built SageMath or Circom, consider restarting your system to ensure everything is loaded."
