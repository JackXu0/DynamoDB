import java.util.*;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.ArrayList;
import java.util.Random;
import java.util.SortedMap;
import java.util.TreeMap;

// TODO: Add function broadcast (worker_map, msg)



public class Master {
    // Special stop message to tell the worker to stop.
//    public static final Message Stop = new Message("Stop!");
    static final Map<Worker, BlockingQueue<Message>> global_message_queues = new HashMap();

    static Map<Message, Integer> message_counter = new HashMap<>();

    static BlockingQueue<Message> message_queue = new ArrayBlockingQueue(1024);

    static Map<Integer, BlockingQueue<Message>> queues = new HashMap<Integer, BlockingQueue<Message>>();

    // Temporary seed worker
    static Worker seed_worker = new Worker();

    static void make_request(Message msg){
        // Get virtual nodes ring from a seed worker
        VirtualNodeRing virtual_nodes_ring = seed_worker.getVirtualNodesRing();
        // Find coordinator node
        VirtualNode coordinator_node = virtual_nodes_ring.getCoordinatorNode(msg.key.hashCode());
        // Find worker
        Worker worker = coordinator_node.worker;
        // Starting count response for this message
        message_counter.put(msg, 0);
        // Put message to worker's message queue
        worker.message_queue.add(msg);
    }

    static void send_put_request(String key, String value){
        // Create Message
        Message msg = new Message(0, key, value);
        make_request(msg);
    }

    static void send_get_request(String key){
        // Create Message
        Message msg = new Message(1, key);
        make_request(msg);
    }

    //TODO: added a runnable method dealing with message queue

//    static void test() throws InterruptedException {
//        // Keep track of my threads.
//        List<Thread> threads = new ArrayList<Thread>();
//        for (int i = 0; i < 20; i++) {
//            // Make the queue for it.
//            BlockingQueue<Message> queue = new ArrayBlockingQueue<Message>(10);
//            // Build its thread, handing it the queue to use.
//            Thread thread = new Thread(new Worker(queue), "Worker-" + i);
//            threads.add(thread);
//            // Store the queue in the map.
//            queues.put(i, queue);
//            // Start the process.
//            thread.start();
//        }
//
//        // Test one.
//        queues.get(5).put(new Message("Hello"));
//
//        // Close down.
//        for (BlockingQueue<Message> q : queues.values()) {
//            // Stop each queue.
//            q.put(Stop);
//        }
//
//        // Join all threads to wait for them to finish.
//        for (Thread t : threads) {
//            t.join();
//        }
//    }

    public static void main(String args[]) throws InterruptedException {
//        test();
        MerkleTree root = new MerkleTree(2, 0);
        for(int i=0; i<10; i++){
            root.add(new MerkleTree.LeafNode(i+"", i+"", i));
        }

        root.print();
    }
}

////////////////////////////////////////////////////////////////////////////////////////
// ignore this class for now
//class KV {
//    private String key;
//    private String value;
//    private ArrayList<Pair<Worker, Integer>> timestamp;
//
//    public KV(String key, String value) {
//        this.key = key;
//        this.value = value;
//    }
//
//    public void modifier(Worker worker) {
//        boolean find = false;
//        for (Pair<Worker, Integer> i: this.timestamp ) {
//            if (i.First() == worker) {
//                i.Second(i.Second() + 1);
//                return;
//            }
//        }
//        timestamp.add(new Pair<Worker, Integer>(worker, 1));
//        return;
//    }
//
//    public String Key() {
//        return this.key;
//    }
//
//    public String Value() {
//        return this.value;
//    }
//
//    public ArrayList<Pair<Worker, Integer>> timeStamp() {
//        return this.timestamp;
//    }
//}




