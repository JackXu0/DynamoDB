import util.Pair;

import java.util.*;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;

public class Worker implements Runnable {
    // List<String> storing membership changing history
    List<String> membership_changing_history = new ArrayList<>();
    // List<VirtualNode> storing the ring of virtual nodes
    // this is my VNs on creation
    private VirtualNodeRing virtual_nodes_ring;
    // Name of this worker
    private String name;
    private int partition;
    private int read;
    private int write;
    // Map<Worker, Boolean> storing the status for each worker node
    private Map<Worker,Boolean> worker_map = new HashMap<>(); //(worker, up or down)
    //TODO: Add a field indicating whether this worker is a seed
    public boolean is_seed = false;

    private Worker seed_worker;

    //TODO: Add total number of workers, and total number of failed workers
    private int num_workers;
    private int num_failed_workers;

    // All corresponding virtual nodes
    private List<VirtualNode> virtualNodes;

    //TODO: Add a Merkel tree for each partition
    private ArrayList<MerkleTree> merkleTrees;

    //TODO: Add a field Map<String, String> records storing all key-value pairs
    private  ArrayList<KVPairsPerPartition> storage;

    private boolean stop = false;
    public BlockingQueue<Message> message_queue;

    // Map to a set of tokens (Virtual nodes) on initialization.
    // TODO: generate two virtual nodes
    // TODO: broadcast to everyone about the arrival of this worker, and the virtual nodes it chose
    // TODO: constructor should be Worker(Worker seed)

    // empty constructor
    public Worker(String name) {
        this.name = name;
    }

    // Create a new worker node
    // 1. create all virtual nodes, and inform the seed node
    // 2. initialize the message queue
    // 3. initialize merkle trees
    // 4. initialize storage

    public Worker(String name, Worker seed_worker, Integer num_partition, Integer read, Integer write) {
        this.name = name;
        this.partition = num_partition;
        this.read = read;
        this.write = write;
        this.seed_worker = seed_worker;
        this.virtualNodes = new ArrayList<>();
        // TODO: Modified here
        SortedMap<String, VirtualNode> virtual_node_ring= new TreeMap<>();
        while (num_partition > 0) {
            Random rand = new Random();
            String hash = Util.getMD5(rand.nextInt()+"");
            VirtualNode VN = new VirtualNode(this, hash, num_partition);
            //TODO: inform the seed node
            virtual_node_ring.put(hash, VN);
            virtualNodes.add(VN);
            num_partition--;
        }
        this.virtual_nodes_ring = new VirtualNodeRing(virtual_node_ring);
        this.message_queue = new ArrayBlockingQueue<Message>(1024);
        this.merkleTrees = new ArrayList();
        this.storage = new ArrayList();
    }

    // A method for seed worker
    public void updateVirtualNodeRing(Worker new_worker){
        for(VirtualNode vn : new_worker.virtualNodes){
            this.virtual_nodes_ring.put(vn);
        }
    }

    //
    public void updateVirtualNodeRing(VirtualNodeRing new_vnr){
        String[] new_hash_arr = new_vnr.getVirtualNodeHashArray();
        String[] local_hash_arr = this.virtual_nodes_ring.getVirtualNodeHashArray();

        
    }

    public VirtualNodeRing getVirtualNodesRing() {
        return virtual_nodes_ring;
    }

    public void getMessage(Message msg) {
        this.message_queue.add(msg);
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
    //TODO: Function to request synchronization (storage)

    //TODO: Function to handle response (virtual_nodes_ring, worker_map) -- update merkel tree if necessary
    //TODO: Function to handle response (membership_changing_history)
    //TODO: Function to handle response (merkel_tree) 
    //TODO: Function to handle response (storage)

    //TODO: Function for Seed Worker:
    // if received message from an unknown worker,
    // add the virtual nodes of this worker to virtual_nodes_ring and the worker to worker_map
    // send to it the new virtual_nodes_ring and new worker_map info





    public void store(Integer VN_patition, Pair<String, String> message) {
        //this.Storage.get(VN_patition).put(message.first(), message.second());

    }

//    public String getIP(){
//        return ip;
//    }

    @Override
    public void run() {
//        while (!stop) {
//            try {
//                Message msg = message_queue.poll(10, TimeUnit.SECONDS);
//                // Handle the message
//                int type = msg.type;
//                switch(type){
//                    // handle put request from master to worker
//                    case 0 :
//                        // Get hash
//                        int hash = msg.key.hashCode();
//                        // Get partition id
//                        int partition_id = virtual_nodes_ring.getCoordinatorNode(hash).partition;
//                        // Add this key value pair to storage
//                        storage.get(partition_id).add(msg.key, msg.value, this);
//                        // Get versions of this new KV pair
//                        Map<Worker, Integer> versions = storage.get(partition_id).getVersions(msg.key);
//                        String value = storage.get(partition_id).getValue(msg.key);
//                        // Create a KV Pair
//                        KVPair kvPair = new KVPair(msg.key, value, versions);
//                        // Add to merkle tree
//
//                        // Broadcast to the following N-1 workers
//
//                        // Update storage
//                        break;
//                }
//
//                System.out.println("Worker " + Thread.currentThread().getName() + " got message " + msg);
//                // Is it my special stop message.
//                if (msg == Master.Stop) {
//                    stop = true;
//                }
//            } catch (InterruptedException ex) {
//                // Just stop on interrupt.
//                stop = true;
//            }
//        }
    }
}