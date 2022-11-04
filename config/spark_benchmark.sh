set -eu

if [[ $# -lt 1 ]] ; then
        echo ""
        echo "usage: spark_benchmark.sh [nodes]"
        echo "for example: spark_benchmark.sh node105,node106,node107"
        echo ""
        exit 1
fi

socket_port=9999
benchmark_amount=100
batch_amount=10
sleep=1
boot_sleep=30

echo "Deploying spark on ${1}"
nodes=${1}
IFS=',' read -ra node_list <<< "$nodes"; unset IFS
master=${node_list[0]}
worker=${node_list[@]:1}
echo "master is "$master
echo "worker is "$worker

#Comment out these lines if you already downloaded them.
wget -O /var/scratch/$USER/spark-3.1.2-bin-hadoop2.7.tgz https://archive.apache.org/dist/spark/spark-3.1.2/spark-3.1.2-bin-hadoop2.7.tgz && \
tar -xf /var/scratch/$USER/spark-3.1.2-bin-hadoop2.7.tgz -C /var/scratch/$USER && mv /var/scratch/$USER/spark-3.1.2-bin-hadoop2.7 /var/scratch/$USER/spark
wget -O /var/scratch/$USER/openjdk-11.0.2_linux-x64_bin.tar.gz https://download.java.net/java/GA/jdk11/9/GPL/openjdk-11.0.2_linux-x64_bin.tar.gz && \
tar -zxf /var/scratch/$USER/openjdk-11.0.2_linux-x64_bin.tar.gz -C /var/scratch/$USER
wget -O /var/scratch/$USER/redis-stable.tar.gz https://download.redis.io/redis-stable.tar.gz && \
tar -xf /var/scratch/$USER/redis-stable.tar.gz -C /var/scratch/$USER/

cd /var/scratch/$USER/redis-stable && make

for n in ${worker}; do
ssh -T $n "mkdir -p /local/$USER/ && cp -r -f /var/scratch/$USER/redis-stable /local/$USER/ && /local/$USER/redis-stable/src/redis-server --daemonize yes && exit"
done

ssh -T $master "mkdir -p /local/$USER/ && cp -r -f /var/scratch/$USER/redis-stable /local/$USER/ && /local/$USER/redis-stable/src/redis-server --daemonize yes && exit"


cd /var/scratch/$USER/spark/conf && cp spark-env.sh.template spark-env.sh && cp workers.template workers

sleep 3

echo "export JAVA_HOME=/var/scratch/$USER/jdk-11.0.2" >> spark-env.sh
echo "export SPARK_MASTER_HOST=$master" >> spark-env.sh
echo "$worker" > workers

# Starting all the nodes
ssh -T $master "/var/scratch/$USER/spark/sbin/start-all.sh"
ssh $master "cd /var/scratch/$USER/spark && ./bin/spark-submit --jars /home/$USER/DDPS-AS1/spark-redis-streaming/executables/spark-redis_2.12-3.1.0-SNAPSHOT-jar-with-dependencies.jar /home/$USER/DDPS-AS1/spark-redis-streaming/executables/spark-redis-entry_2.12-1.0.jar $master $socket_port"