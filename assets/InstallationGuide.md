# Ballot Validity Repository
If git is not installed already, install it with 
```bash
sudo apt install git-all
```
Then, clone the repository into the desired directory `$HOME` by running the following command in this repository:
```bash
git clone https://git.sec.uni-stuttgart.de/scm/repo/huber/roehr
```

# Circom
We will install Circom in the directory `$HOME` where we also cloned the Ballot Validity repository. Open a terminal in this directory.

We are following the [installation guide](https://docs.circom.io/getting-started/installation/) for Circom.

1. First, we need to install some dependencies:
```bash
curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh
sudo apt install npm nodejs cargo
```

2. Then, we can install Circom by cloning the repository and then building with cargo.
```bash
git clone https://github.com/iden3/circom.git
cd circom
cargo build --release
cargo install --path circom
```
3. To be able to use Circom, we need to add `$HOME/.cargo/bin` to the `PATH`. To do this, run the following command (Replace `$HOME` according to your system):
```bash
export PATH="$HOME/.cargo/bin:$PATH"
```
4. Restart your system. After that you should be able to see the Circom compile options by running `circom --help`.

5. Since there is an option to use C++ witness generation in our system we also need to install the libraries `nlohmann-json3-dev`, `libgmp-dev` and `nasm`. To do so, run the following:
```bash
sudo apt install nlohmann-json3-dev libgmp-dev nasm
```

# snarkjs
1. To install snarkjs, simply run the following:
```bash
sudo npm install -g snarkjs
```

2. The benchmarks in the Ballot Validity repository requires some predefined powers-of-tau file for zk proof generation.
For small candidate counts, the file `powersOfTau28_hez_final_22.ptau` from the [snarkjs github](https://github.com/iden3/snarkjs?tab=readme-ov-file) is sufficient and included in this repository.
For our benchmarks, we used the file `powersOfTau_hez_final_25.ptau` from the [snarkjs github](https://github.com/iden3/snarkjs?tab=readme-ov-file). Since this file is very large (36 GB!), we recommend to download this, only if you want to run benchmarks for proving ballot validity for very large candidate counts.
In that case, please save the file in the folder `src/scripts/ptau`.
Our implementation will automatically use the largest file present in that folder.

# SageMath
Some Linux distributions have current versions of SageMath available (E.g., ArchLinux). 
However, for many Linux distributions, this is not the case. 
Therefore, we have found the option presented [here](https://sagemanifolds.obspm.fr/install_ubuntu.html) to be the most convenient to install SageMath:
1. Install SageMath Dependencies:
```bash
sudo apt install automake bc binutils bzip2 ca-certificates cliquer cmake curl ecl eclib-tools fflas-ffpack flintqs g++ gengetopt gfan gfortran git glpk-utils gmp-ecm lcalc libatomic-ops-dev libboost-dev libbraiding-dev libbz2-dev libcdd-dev libcdd-tools libcliquer-dev libcurl4-openssl-dev libec-dev libecm-dev libffi-dev libflint-dev libfreetype-dev libgc-dev libgd-dev libgf2x-dev libgiac-dev libgivaro-dev libglpk-dev libgmp-dev libgsl-dev libhomfly-dev libiml-dev liblfunction-dev liblrcalc-dev liblzma-dev libm4rie-dev libmpc-dev libmpfi-dev libmpfr-dev libncurses-dev libntl-dev libopenblas-dev libpari-dev libpcre3-dev libplanarity-dev libppl-dev libprimesieve-dev libpython3-dev libqhull-dev libreadline-dev librw-dev libsingular4-dev libsqlite3-dev libssl-dev libsuitesparse-dev libsymmetrica2-dev zlib1g-dev libzmq3-dev libzn-poly-dev m4 make nauty openssl palp pari-doc pari-elldata pari-galdata pari-galpol pari-gp2c pari-seadata patch perl pkg-config planarity ppl-dev python3-setuptools python3-venv r-base-dev r-cran-lattice singular sqlite3 sympow tachyon tar tox xcas xz-utils 
```

2. Install optional extra functionalities:
```bash
sudo apt install texlive-latex-extra texlive-xetex latexmk pandoc dvipng
sudo apt-get install 4ti2 gpgconf openssh-client default-jdk libavdevice-dev coinor-cbc coinor-libcbc-dev ffmpeg fonts-freefont-otf fricas libigraph-dev imagemagick libisl-dev libgraphviz-dev libnauty-dev lrslib libtbb-dev pdf2svg libxml-libxslt-perl libxml-writer-perl libxml2-dev libperl-dev libfile-slurp-perl libjson-perl libsvg-perl libterm-readkey-perl libterm-readline-gnu-perl libmongodb-perl libterm-readline-gnu-perl polymake libpolymake-dev sbcl texlive-luatex xindy
```

3. Dowload SageMath 10.5 sources by cloning the github repository and launch the build:
```bash
git clone --branch master https://github.com/sagemath/sage.git
cd sage
make configure
./configure
MAKE="make -j8" make
```
The `8` in the last command means that the installation utilizes $8$ threads during the installation. You can change this to at most twice the number of cores your system has to accelerate installation. (Although we tried this with $32$ on our system with 16 cores and it crashed. When we tried it again with $16$ it worked fine. So we would be careful with this.)

4. To be able to use SageMath from the terminal anywhere on your system, add a symbolic link:
```bash
sudo ln -sf $(pwd)/sage /usr/local/bin
```

5. To validate the installation, run `sage -n`. This should open a Jupyter page in your browser where you could open a new Jupyter notebook with a Sagemath 10.5 kernel.

# PATH and PYTHONPATH
In order benchmarks, Circom witness generation, snarkjs proof generation and verification and several other scripts to work, we need to add some entries to `PATH` and `PYTHONPATH`:
- Add to `PATH`: `$HOME/roehr/src/scripts` and `$HOME/roehr/src/scripts/snarkjs`
- Add to `PYTHONPATH`: `$HOME/roehr/src/scripts`

We can do this by running the following commands:
```bash
export PATH="$HOME/roehr/src/scripts:$HOME/roehr/src/scripts/snarkjs:$PATH"
export PYTHONPATH="$HOME/roehr/src/scripts:$PYTHONPATH"
```

You can verify that the appropriate entries are in `PATH` and `PYTHONPATH` by printing them:
```bash
echo $PATH
echo $PYTHONPATH
```

Optionally, to keep your `PATH` and `PYTHONPATH` clean and free from duplicates, we also recommend adding the following lines to your `~/.bashrc` file:
```bash
# Remove duplicate entries from PATH
clean_path() {
    export PATH=$(echo "$PATH" | awk -v RS=: '!a[$1]++' | paste -sd:)
    export PYTHONPATH=$(echo "$PYTHONPATH" | awk -v RS=: '!a[$1]++' | paste -sd:)
}
clean_path
```

# Optional: VsCode extensions

If you are using Visual Studio Code for development we recommend the installation of the following extensions:
- [Circom Pro](vscode:extension/tintinweb.vscode-circom-pro)
- [circom-highlighting-vscode](vscode:extension/iden3.circom)
- [SageMath Enhanced](vscode:extension/Lov3.sagemath-enhanced)
- [Python](vscode:extension/ms-python.python)

<!-- [The link text](vscode:extension/*the-extension-id*) -->
