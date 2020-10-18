FROM carlasim/carla:0.9.6 as carla
FROM nvidia/cuda:10.0-devel-ubuntu16.04
RUN packages='libsdl2-2.0' \
	&& apt-get update && apt-get install -y $packages --no-install-recommends \
	&& rm -rf /var/lib/apt/lists/*

RUN useradd -m carla

COPY --from=carla --chown=carla:carla . /home/carla

ENV SDL_VIDEODRIVER=offscreen

ENV HADOOP_VERSION=2.7.2
LABEL HADOOP_VERSION=2.7.2

RUN DEBIAN_FRONTEND=noninteractive && \
    apt-get -y update && \
    apt-get -y install python \
        python-pip \
        python-dev \
        python3 \
        python3-pip \
        python3-dev \
        python-yaml \
        python-six \
        build-essential \
        wget \
        curl \
        unzip \
        automake \
        openjdk-8-jdk \
        openssh-server \
        openssh-client \
        lsof \
        libcupti-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN wget -qO- http://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz | \
    tar xz -C /usr/local && \
    mv /usr/local/hadoop-${HADOOP_VERSION} /usr/local/hadoop

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 \
    HADOOP_INSTALL=/usr/local/hadoop \
    NVIDIA_VISIBLE_DEVICES=all

ENV HADOOP_PREFIX=${HADOOP_INSTALL} \
    HADOOP_BIN_DIR=${HADOOP_INSTALL}/bin \
    HADOOP_SBIN_DIR=${HADOOP_INSTALL}/sbin \
    HADOOP_HDFS_HOME=${HADOOP_INSTALL} \
    HADOOP_COMMON_LIB_NATIVE_DIR=${HADOOP_INSTALL}/lib/native \
    HADOOP_OPTS="-Djava.library.path=${HADOOP_INSTALL}/lib/native"

ENV PATH=/usr/local/nvidia/bin:/usr/local/cuda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${HADOOP_BIN_DIR}:${HADOOP_SBIN_DIR}:${PATH} \
    LD_LIBRARY_PATH=/usr/local/cuda/extras/CUPTI/lib:/usr/local/cuda/extras/CUPTI/lib64:/usr/local/nvidia/lib:/usr/local/nvidia/lib64:/usr/local/cuda/lib64:/usr/local/cuda/targets/x86_64-linux/lib/stubs:${JAVA_HOME}/jre/lib/amd64/server:{LD_LIBRARY_PATH}

RUN apt-get update --fix-missing && \
    apt-get install -y \
        software-properties-common && \
    add-apt-repository -y ppa:deadsnakes/ppa && \
    apt-get install -y \
    python3.6 \
    python3.6-dev \
    libpng16-16 \
    libjpeg-turbo8 \
    libtiff5 

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.6 1

# Install pip dependencies
RUN wget https://bootstrap.pypa.io/get-pip.py -O get-pip.py && \
    python get-pip.py && \
    pip install --upgrade pip

RUN pip install tensorflow-gpu==1.15 
RUN pip install torch==1.4+cu100 torchvision==0.5+cu100 -f https://download.pytorch.org/whl/torch_stable.html
RUN pip install ray==0.8.6
RUN pip install gym
RUN pip install pygame
RUN pip install opencv-python
RUN pip install pandas ray[rllib]

USER carla
WORKDIR /home/carla

