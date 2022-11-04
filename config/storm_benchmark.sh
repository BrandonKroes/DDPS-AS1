#!/bin/sh
if [[ $# -lt 1 ]] ; then
        echo ""
        echo "usage: storm_benchmark.sh [nodes]"
        echo "for example: source storm_benchmark.sh node105,node106,node107"
        echo ""
        exit 1
fi

zk_client_port=9911
socket_port=9999
benchmark_amount=100
batch_amount=10
sleep=1
boot_sleep=30
topology_name="SparkRedisBenchmarkTest"

echo "Deploying storm on ${1}"
nodes=${1}
IFS=',' read -ra node_list <<< "$nodes"; unset IFS
master=${node_list[0]}
worker=${node_list[@]:1}
echo "master is "$master
echo "worker is "$worker

# removing old instances
rm -rf /var/scratch/$USER/apache-zookeeper-3.8.0-bin/
rm -rf /var/scratch/$USER/apache-storm-2.4.0
rm -rf /var/scratch/$USER/zookeeperData


# Ensuring zookeeper is available
wget -O /var/scratch/$USER/apache-zookeeper-3.8.0-bin.tar.gz https://dlcdn.apache.org/zookeeper/zookeeper-3.8.0/apache-zookeeper-3.8.0-bin.tar.gz && \
tar -xvf /var/scratch/$USER/apache-zookeeper-3.8.0-bin.tar.gz -C /var/scratch/$USER/ >/dev/null 2>&1
# Ensuring storm is available
wget -O /var/scratch/$USER/apache-storm-2.4.0.tar.gz https://dlcdn.apache.org/storm/apache-storm-2.4.0/apache-storm-2.4.0.tar.gz && \
tar -xvzf /var/scratch/$USER/apache-storm-2.4.0.tar.gz -C /var/scratch/$USER/ >/dev/null 2>&1
# Ensuring java is available
wget -O /var/scratch/$USER/openjdk-11.0.2_linux-x64_bin.tar.gz https://download.java.net/java/GA/jdk11/9/GPL/openjdk-11.0.2_linux-x64_bin.tar.gz && \
tar -zxf /var/scratch/$USER/openjdk-11.0.2_linux-x64_bin.tar.gz -C /var/scratch/$USER/ >/dev/null 2>&1

# Ensuring Redis available
wget -O /var/scratch/$USER/redis-stable.tar.gz https://download.redis.io/redis-stable.tar.gz && \
tar -xf /var/scratch/$USER/redis-stable.tar.gz -C /var/scratch/$USER/ >/dev/null 2>&1
cd /var/scratch/$USER/redis-stable && make


# Setting up zookeeper
mkdir -p /var/scratch/$USER/zookeeperData
touch /var/scratch/$USER/apache-zookeeper-3.8.0-bin/conf/zoo.cfg
echo $"tickTime=2000" >> /var/scratch/$USER/apache-zookeeper-3.8.0-bin/conf/zoo.cfg
echo $"dataDir=/var/scratch/$USER/zookeeperData" >> /var/scratch/$USER/apache-zookeeper-3.8.0-bin/conf/zoo.cfg
echo $"clientPort=$zk_client_port" >> /var/scratch/$USER/apache-zookeeper-3.8.0-bin/conf/zoo.cfg
echo $"# Enable regular purging of old data and transaction logs every hour" >> /var/scratch/$USER/apache-zookeeper-3.8.0-bin/conf/zoo.cfg
echo $"autopurge.purgeInterval=1" >> /var/scratch/$USER/apache-zookeeper-3.8.0-bin/conf/zoo.cfg
echo $"autopurge.snapRetainCount=0" >> /var/scratch/$USER/apache-zookeeper-3.8.0-bin/conf/zoo.cfg
echo $"admin.serverPort=9991" >> /var/scratch/$USER/apache-zookeeper-3.8.0-bin/conf/zoo.cfg
# Setting up Storm
cd /var/scratch/$USER/apache-storm-2.4.0/conf

# Assigning nimbus and zookeeper nodes to storm config
echo $"storm.zookeeper.servers:" >> storm.yaml
echo $"     - '$master'" >> storm.yaml
echo $"nimbus.seeds: ['$master']" >> storm.yaml
echo $"storm.zookeeper.port : $zk_client_port" >> storm.yaml

# Starting zookeeper
ssh -T $master "nohup /var/scratch/$USER/apache-zookeeper-3.8.0-bin/bin/zkServer.sh start  &"

# Starting Storm nimbus
ssh -T $master "nohup /var/scratch/$USER/apache-storm-2.4.0/bin/storm nimbus > storms.log  &"
sleep 10 # launching zookeeper can take some time

echo "Starting supervisors on each worker node"
for n in ${worker}; do
echo "Starting Redis"
ssh -T $n "mkdir -p /local/$USER/ && cp -r -f /var/scratch/$USER/redis-stable /local/$USER/ && /local/$USER/redis-stable/src/redis-server --daemonize yes && exit"
echo "Copying storm"
ssh -T $n "cp -r -f /var/scratch/$USER/apache-storm-2.4.0 /local/$USER/ && exit"
# Starting storm
echo "Starting storm for $n"
ssh -T $n "nohup ./local/$USER/apache-storm-2.4.0/bin/storm supervisor > storms.log &"

done
sleep 5 # launching all workers can take some time


echo "Finally, telling nimbus to start the benchmark."
ssh -T $master "/var/scratch/$USER/apache-storm-2.4.0/bin/storm jar /home/$USER/DDPS-AS1/storm-socket-redis/executables/SocketToRedis-2.4.0.jar org.apache.storm.redis.SocketToRedis 127.0.0.1 6379 127.0.0.1 $socket_port $topology_name"
