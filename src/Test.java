import java.util.*;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.ArrayList;
import java.util.Random;
import java.util.SortedMap;
import java.util.TreeMap;

public class Test {
    // Special stop message to tell the worker to stop.
    public static final Message Stop = new Message("Stop!");

    static Map<Integer, BlockingQueue<Message>> queues = new HashMap<Integer, BlockingQueue<Message>>();

    static void test() throws InterruptedException {
        // Keep track of my threads.
        List<Thread> threads = new ArrayList<Thread>();
        for (int i = 0; i < 20; i++) {
            // Make the queue for it.
            BlockingQueue<Message> queue = new ArrayBlockingQueue<Message>(10);
            // Build its thread, handing it the queue to use.
            Thread thread = new Thread(new Worker(queue), "Worker-" + i);
            threads.add(thread);
            // Store the queue in the map.
            queues.put(i, queue);
            // Start the process.
            thread.start();
        }

        // Test one.
        queues.get(5).put(new Message("Hello"));

        // Close down.
        for (BlockingQueue<Message> q : queues.values()) {
            // Stop each queue.
            q.put(Stop);
        }

        // Join all threads to wait for them to finish.
        for (Thread t : threads) {
            t.join();
        }
    }

    public static void main(String args[]) throws InterruptedException {
        test();
    }

}

class Message {
    private final boolean get;
    private final Pair<String, String> msg;
    private ArrayList<Pair<>> timestamp

    // A message to a worker.
    public Message(Boolean get, Pair<String, String> msg) {
        this.msg = msg;
        this.get = get;
    }

    public String toString() {
        return msg;
    }

}

////////////////////////////////////////////////////////////////////////////////////////
// ignore this class for now
class KV {
    private String key;
    private String value;
    private ArrayList<Pair<Worker, Integer>> timestamp;

    public KV(String key, String value) {
        this.key = key;
        this.value = value;
    }

    public void modifier(Worker worker) {
        boolean find = false;
        for (Pair<Worker, Integer> i: this.timestamp ) {
            if (i.First() == worker) {
                i.Second(i.Second() + 1);
                return;
            }
        }
        timestamp.add(new Pair<Worker, Integer>(worker, 1));
        return;
    }

    public String Key() {
        return this.key;
    }

    public String Value() {
        return this.value;
    }

    public ArrayList<Pair<Worker, Integer>> timeStamp() {
        return this.timestamp;
    }
}

////////////////////////////////////////////////////////////////////////////////////////
// contains kv pairs stored in one partition
class kvList {
    // Map<key, <value, time stamp>>
    private Map<String, Pair<String, Map<Worker, Integer>>> list;

    public kvList() {
        this.list = new HashMap<>();
    }

    public void add(String key, String value, Worker worker) {
        // TODO(NOT HERE): compare hash of both value and key so that the merkle tree can work correctly
        if (list.containsKey(key)) {
            Map<Worker, Integer> timestamp = list.get(key).second();
            if (timestamp.containsKey(worker))
                timestamp.put(worker, timestamp.get(worker) + 1);
            else
                timestamp.put(worker, 1);
        } else {
            Map<Worker, Integer> timestamp = new HashMap<>();
            timestamp.put(worker, 1);
            list.put(key, new Pair(value, timestamp));
        }
    }

    public String getValue(String key) {
        return this.list.get(key).first();
    }

    public Map<Worker, Integer> getTimeStamp(String key) {
        return this.list.get(key).second();
    }
}
////////////////////////////////////////////////////////////////////////////////////////

class VirtualNode {
    Worker worker;
    int hash;
    int partition;

    //TODO: add previous virtual node field  (abort?)
    //TODO: add previous virtual node hash field (abort?)

    public VirtualNode(Worker worker, int hash, int partition){
        this.worker = worker;
        this.hash = hash;
        this.partition = partition;
    }

}

////////////////////////////////////////////////////////////////////////////////////////

class MerkleTree {
    private int hash; // remember calculate both value and key
    private MerkleTree left;
    private MerkleTree right;
}

////////////////////////////////////////////////////////////////////////////////////////
// TODO: Add function broadcast (worker_map, msg)


class Worker implements Runnable {
    // List<String> storing membership changing history
    List<String> membership_changing_history = new ArrayList<>();
    // List<VirtualNode> storing the ring of virtual nodes
    // this is my VNs on creation
    private SortedMap<Integer,VirtualNode> virtual_nodes_ring = new TreeMap<Integer, VirtualNode>();;
    // Map<Worker, Boolean> storing the status for each worker node
    private Map<Worker,Boolean> worker_map = new HashMap<>(); //(worker, up or down)
    //TODO: Add a field indicating whether this worker is a seed
    private boolean is_seed = false;

    public boolean isSeed() {
        return this.is_seed;
    }

    public void isSeed(boolean x) {
        this.is_seed = x;
    }


    //TODO: Add total number of workers, and total number of failed workers
    private int num_workers;
    private int num_failed_workers;

    //TODO: Add a Merkel tree for each partition
    private ArrayList<MerkleTree> storage_record;

    //TODO: Add a field Map<String, String> records storing all key-value pairs
    private  ArrayList<kvList> storage;

    private boolean stop = false;
    private final BlockingQueue<Message> workQueue;

    // Map to a set of tokens (Virtual nodes) on initialization.
    // TODO: generate two virtual nodes
    // TODO: broadcast to everyone about the arrival of this worker, and the virtual nodes it chose
    // TODO: constructor should be Worker(Worker seed)

    public Worker(BlockingQueue<Message> workQueue, Integer num_partition) {
        this.workQueue = workQueue;

        int partition = 0;
        while (num_partition > 0) {
            Random rand = new Random();
            Integer hash = rand.nextInt();
            VirtualNode VN = new VirtualNode(this, hash, num_partition);
            this.virtual_nodes_ring.put(hash, VN);

        }
    }



    //TODO: Handle messages from clients
    public void getRequest(Message msg) {
        //TODO: Get the coordinate node
    }

    //TODO: check whether a particular worker is up or down
    private Boolean isWorking(Worker worker) {
        return worker_map.get(worker);
    }

    //TODO: handle get/put requests

    //TODO: transfer a partition to another worker (start_hash, end_hash, destination_worker)

    //TODO: received a partition from another worker (records)

    //TODO: Implement a timer to synchronize data with other workers

    //TODO: Function to request synchronization (virtual_nodes_ring, worker)
    //TODO: Function to request synchronization (membership_changing_history)
    //TODO: Function to request synchronization (merkel_tree)
    //TODO: Function to request synchronization (vector_time)

    //TODO: Function to handle response (virtual_nodes_ring, worker_map) -- update merkel tree if necessary
    //TODO: Function to handle response (membership_changing_history)
    //TODO: Function to handle response (merkel_tree)
    //TODO: Function to handle response (vector_time)

    //TODO: Function for Seed Worker:
    // if received message from an unknown worker,
    // add the virtual nodes of this worker to virtual_nodes_ring and the worker to worker_map
    // send to it the new virtual_nodes_ring and new worker_map info





    public void store(Integer VN_patition, Pair<String, String> message) {
        //this.Storage.get(VN_patition).put(message.first(), message.second());

    }

    public String getIP(){
        return ip;
    }

    @Override
    public void run() {
        while (!stop) {
            try {
                Message msg = workQueue.poll(10, TimeUnit.SECONDS);
                // Handle the message ...

                System.out.println("Worker " + Thread.currentThread().getName() + " got message " + msg);
                // Is it my special stop message.
                if (msg == Test.Stop) {
                    stop = true;
                }
            } catch (InterruptedException ex) {
                // Just stop on interrupt.
                stop = true;
            }
        }
    }
}

class Master implements Runnable {
    private boolean stop = false;
    private ArrayList workers;
    private Integer num_Workers;
    private Integer num_VN;
    private Integer num_replication;
    private List<VirtualNode> virtualNodes;
    private HashMap<Integer, Pair<Worker, Integer>> VN_to_worker;

    public Master(ArrayList<Worker> workers, Integer num_partition, Integer num_replication) {
        this.workers = workers;
        this.num_replication = num_replication;
        this.num_Workers = workers.size();
        this.num_VN = this.num_Workers * num_partition;
        this.VN_to_worker = new HashMap<Integer, Pair<Worker, Integer>>(); //<VN_id, <worker, partition_id>>
        Integer VN_id = 0;
        for (Integer VN_partition = 0; VN_partition < num_partition; VN_partition++) {
            for (Worker worker: workers) {
                VN_to_worker.put(VN_id, new Pair<Worker, Integer>(worker, VN_partition));
                VN_id++;
            }
        }
    }

    public void addVirtualNode(VirtualNode vn){
        for(int i=0; i<virtualNodes.size(); i++){
            if(virtualNodes.get(i).hash > vn.hash){
                virtualNodes.add(i, vn);
                return;
            }
        }
        virtualNodes.add(vn);
    }

    public VirtualNode findVirtualNode(int hash){

        for(int i=0; i<virtualNodes.size(); i++){
            if(virtualNodes.get(i).hash > hash)
                return virtualNodes.get(i);
        }
        return virtualNodes.get(0);
    }

    public void deleteVirtualNode(VirtualNode vn){
        virtualNodes.remove(vn);
    }

    private void Save(Pair<String, String> message) {
        //String key = message.first(0); pseudocode
        Integer hashcode = key.hashCode() % this.num_VN;
        Integer save_up_to = hashcode + this.num_replication;
        Boolean turn_around = false;
        if (save_up_to >= num_VN) {
            turn_around = true;
            save_up_to = save_up_to % num_VN;
        }
        while (hashcode < save_up_to || (hashcode > save_up_to && turn_around)) {
            //pseudocode
            Worker worker = this.VN_to_worker.get(hashcode).first();
            Integer VN_partition = this.VN_to_worker.get(hashcode).second();
            worker.store(VN_partition, message)
            hashcode++;
            if (hashcode >= num_VN) {
                hashcode = hashcode % num_VN;
                turn_around = false;
            }
        }
    }

    private Pair<Worker, Integer> getLoc(Message message) {
        //String key = message.first(0); pseudocode
        Integer hashcode = key.hashCode() % this.num_VN;
        return this.VN_to_worker.get(hashcode);
    }

    private Pair<Worker, Integer> getLoc(String key) {
        Integer hashcode = key.hashCode() % this.num_VN;
        return this.VN_to_worker.get(hashcode);
    }



    @Override
    public void run() {
        while (!stop) {
            }
        }
    }


    class Pair<T1, T2> {
        private T1 first;
        private T2 second;

        public Pair(T1 x, T2 y) {
            this.first = x;
            this.second = y;
        }

        public T1 first() {
            return this.first;
        }

        public T2 second() {
            return this.second;
        }

        public void second(T2 second) { this.second = second; }
    }
}


