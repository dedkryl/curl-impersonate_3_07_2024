#see INSTALL.md --> Ubuntu
sudo apt install build-essential pkg-config cmake ninja-build curl autoconf automake libtool
sudo apt install golang-go unzip
mkdir build && cd build
../configure 
make chrome-build
sudo make chrome-install
sudo ldconfig
#cd ../ && rm -Rf build

