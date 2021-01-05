# **Build Docker Image**
docker build -t kafka:2.13 .
# **Run the container from image**
docker run --rm -it --name my-kafka-img kafka:2.13 bash
# **For joining the container session**
docker exec -it $(docker ps -q --filter="NAME=mykafka-img") bash

# **Start the single Kafka Server (broker)**
## Kafka Home: /opt/kafka

cd $KAFKA_HOME
## Start the zookeeper
bin/zookeeper-server-start.sh config/zookeeper.properties
## Start the broker (--bootstrap-server)
bin/kafka-server-start.sh config/server.properties

### Check the port listening as the zookeeper listen on 2181 and broker server listens on 9092
lsof -nP -iTCP -sTCP:LISTEN 



# **For multi broker (--bootstrap-server)**
```cd $KAFKA_HOME
bin/zookeeper-server-start.sh config/zookeeper.properties
cp config/server.properties config/server1.properties
cp config/server.properties config/server2.properties
cp config/server.properties config/server3.properties
```
### Modify the following for server1.properties
```
broker.id=1
listeners= PLAINTEXT://:9093
log.dirs=/tmp/kafka-logs1
```
## Modify the following for server2.properties
```
broker.id=2
listeners= PLAINTEXT://:9094
log.dirs=/tmp/kafka-logs2
```
### Modify the following for server3.properties
```
broker.id=3
listeners= PLAINTEXT://:9095
log.dirs=/tmp/kafka-logs3
```
### Start the brokers
```
bin/kafka-server-start.sh config/server1.properties
bin/kafka-server-start.sh config/server2.properties
bin/kafka-server-start.sh config/server3.properties
```
# **Create a Topic**
```
cd $KAFKA_HOME
bin/kafka-topics.sh --create --topic my-first-topic --zookeeper localhost:2181 --partitions 1 --replication-factor 3
```
**NB: --zookeeper can be replaced by --bootstrap-server and point to the brokers e.g. --bootstrap-server localhost:9092**
### So what we have done is 
Commands:
   - -- topic: topic name
   - ---zookeeper: zookeeper host:port
   - --partitions: How many partitions each broker will have for parallel processing
   - --replication-factor: How many partition copies of data to be kept for fault tolerance [**The number of replication is equal to the number of brokers as each partitions resides inside the broker.**]
   

#### So the above command is telling that we want to create a topic which will be having 1 partition across the botstrap server and with 3 replicas. This can be verified by the following.
```
bin/kafka-topics.sh --describe --topic my-first-topic --zookeeper localhost:2181
*Topic: my-first-topic   PartitionCount: 1       ReplicationFactor: 3    Configs: Topic: my-first-topic   Partition:     Leader: 3       Replicas: 3,1,2  Isr: 3,1,2*
```
### So the above tells zookeeper though we have 3 brokers listening on 9093,9094,9095 to elect one as leader which is 3 in our case and (1 and 2 are worker). Also under each we have 3 replicas of data store.
**Replicas**: There are 3 replication of our data which zookeeper matching with ISR (In-Sync Replicas) to tolerate leader/worker failure.

### With all this set let us publish some messages and consume that in another session.
```
bin/kafka-console-producer.sh --bootstrap-server localhost:9093 --topic my-first-topic
First Message
Second Message

bin/kafka-console-consumer.sh --bootstrap-server localhost:9094 --topic my-first-topic --from-beginning
First Message
Second Message
```
**Notice here we have different ports added for producer and consumer but this is managed by the zookeeper which is the leader node and which are workers. So the message will flow to the leader and then the leader will flow the messages to the workers. Each of the messages are replicated thrice as replica is 3.**

### Lets do some fault-tolerance test by shutting down the broker 2 listening on 9094
once we shut it down then lets see the description of the topic.
```
bin/kafka-topics.sh --describe --topic my-first-topic --zookeeper localhost:2181
```
Topic: my-first-topic   PartitionCount: 1       ReplicationFactor: 3    Configs:
    Topic: my-first-topic   Partition: 0    Leader: 3       Replicas: 3,1,2  *Isr: 3,1*
Zookeeper found the broker number 2 is unhealthy and updated the in-sync-replicas to 2 and thats 3,1. 

*Also after we restart the broker2 again it will show like this.*
```
bin/kafka-topics.sh --describe --topic my-first-topic --zookeeper localhost:2181
```
Topic: my-first-topic   PartitionCount: 1       ReplicationFactor: 3    Configs: 
        Topic: my-first-topic   Partition: 0    Leader: 3       Replicas: 3,1,2  *Isr: 3,1,2*

**Lets do another test by shutting down the number 3 which is our leader.**
```
bin/kafka-topics.sh --describe --topic my-first-topic --zookeeper localhost:2181
```
Topic: my-first-topic   PartitionCount: 1       ReplicationFactor: 3    Configs: 
        Topic: my-first-topic   Partition: 0    **Leader: 1**      Replicas: 3,1,2  *Isr: 1,2*

The leader is now switched to 1 from 3 as zookeeper found its unhealthy.

Also as the producer and consumer knew it was the leader previously so, it will show some warning in consumer window.

***WARN [Consumer clientId=consumer-console-consumer-95639-1, groupId=console-consumer-95639] Connection to node 3 (<container/<ip>:9095) could not be established. Broker may not be available. (org.apache.kafka.clients.NetworkClient)***
Lets publish some messages and consume that.
```
   bin/kafka-console-producer.sh --bootstrap-server localhost:9093 --topic my-first-topic
```   
 Third message

Now consume that from may be broker 2
Third message

Lets start now the 3rd broker and see what happens.. 
```
bin/kafka-topics.sh --describe --topic my-first-topic --zookeeper localhost:2181
```
Topic: my-first-topic   PartitionCount: 1       ReplicationFactor: 3    Configs: 
        Topic: my-first-topic   Partition: 0    **Leader: 1**       Replicas: 3,1,2    *Isr: 1,2,3*

Here Leader remains same but ISR is updated. Lets consume messages from this broker which is just started and unknown about the Third Message.
```
bin/kafka-console-consumer.sh --bootstrap-server localhost:9095 --topic my-first-topic --from-beginning
```
Hello
Bye
**Third message** <-- Walla !! this is how zookeeper robust in its own ways.. the third message immediately replicated to that broker and its in sync which is also updated by zookeeper above *Isr: 1,2,3*





