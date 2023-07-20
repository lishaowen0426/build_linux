FROM ubuntu:22.10

RUN apt-get update
RUN apt-get install -y \
    bc \
    bison \
	wget \
	unzip \
	rsync \
    build-essential \
	pkg-config \
	sed \
	binutils \
	diffutils \		
	perl \
	file \
	findutils \
    cpio \
    flex \
    libelf-dev \
    libncurses-dev \
    libssl-dev \
    vim-tiny \
    sudo 

ENTRYPOINT ["./build_linux/mount.sh"] 
