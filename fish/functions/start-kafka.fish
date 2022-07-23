function start-kafka
   cd ~/bin/kafka_2.13-3.2.0/
   bin/zookeeper-server-start.sh config/zookeeper.properties &
   bin/kafka-server-start.sh config/server.properties
end
