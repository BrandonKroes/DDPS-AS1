# DAS-5 Storm Vs Spark Benchmark

## Clone instruction
Important, clone using `git clone --recursive https://github.com/BrandonKroes/DDPS-AS1` other wise the submodules won't be downloaded.

## Submodules
The Spark and Storm configurations are both added as git submodules. A detailed description of the inner workings is detailed in the submodules themselves.

## Benchmarks
Running a benchmark entails the following process:
1. Reserve the amount of nodes you wish to test. 
2. Open up **two** terminals towards DAS-5. Using nohup will **NOT** work. 
3. In Terminal 1: run the socket-data-generator.sh. Example `python3 socket-data-generator.py 1000 100 10 1 | nc -lk 9999`. In the example, 1000 records will be generated, 100 a time. The program will sleep for 10 seconds and spend 1 second between batches. The port can be chosen based on preference, but needs to be the same for the benchmark. 
4. In Terminal 2: cd to the /config/ folder and run the Storm or Spark benchmarks followed by nodes with comma seperated, for example `storm-benchmark.sh node102,node103,node104`. 

## After a benchmark is done:
1. Cancel command in terminal 1 & terminal 2.
2. Access Redis on every node used in the test case by SSH-ing into the install. Execute `/local/$USER/redis-stable/src/redis-cli save`. A dump.rdb file can be found in the folder `/local/$USER/redis-stable/src/redis-cli`. The individual results combined represent the entire database. To make this dump.rdb file readable, you can use a [.rdb to .json converter](https://github.com/HDT3213/rdb)