import util.Pair;

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
//        BlockingQueue<Message> message_queue1 = new ArrayBlockingQueue(1024);
//        BlockingQueue<Message> message_queue2 = new ArrayBlockingQueue(1024);
//        Message m1 = new Message(0, "first", "1");
//        Message m2 = new Message(0, "second", "2");
//        Message m3 = new Message(0, "third", "3");
//        Message m4 = new Message(0, "third", "4");
//        message_queue1.add(m1);
//        message_queue1.add(m2);
//        message_queue1.add(m3);
//        message_queue2.add(m1);
//        message_queue2.add(m2);
//        message_queue2.add(m4);
//
//        Worker w1 = new Worker(message_queue1, 2);
//        Worker w2 = new Worker(message_queue2, 2);

        MerkleTree root = new MerkleTree(2, 0);
        MerkleTree root2 = new MerkleTree(2, 0);
//        root.num = 2;
//        root.left = new MerkleTree(new KVPair("1", "1", new HashMap<>()));
//        root.right = new MerkleTree(new KVPair("2", "2", new HashMap<>()));
//        root.print();
//        root.enlargeIfNecessary();
//        root.print();
//        root.num = 4;
//        root.enlargeIfNecessary();

//        // Test for merkle tree insertion

        for(int i=0; i<6; i++){
            root.add(new KVPair(i+"", i+"", 0), i+1);
        }
        root.add(new KVPair(7+"", 88+"",1), 8);
        root.add(new KVPair(6+"", 77+"", 1), 7);
        root.add(new KVPair(8+"", 77+"", 1), 9);

        for(int i=0; i<8; i++){
            root2.add(new KVPair(i+"", i+"", 0), i+1);
        }
        root.print();
        root2.print();
        Pair<Boolean, List<KVPair>> s = root2.synchroize(root);
        List<KVPair> need_update = s.second();
        for (KVPair p : need_update) {
            System.out.println(p.key + " " + p.value + " " + p.version);
        }
        root2.print();

        System.out.println(s);


//
//        // Test for KVPair update
//        Worker w1 = new Worker();
//        Worker w2 = new Worker();
//        HashMap<Worker, Integer> m1 = new HashMap<>();
//        HashMap<Worker, Integer> m2 = new HashMap<>();
//        m1.put(w1, 9); m1.put(w2, 10);
//        m2.put(w1, 1); m2.put(w2, 11);
//        KVPair p1 =  new KVPair("k1", "v1", m1);
//        KVPair p2 =  new KVPair("k2", "v2", m2);
//        p1.update(p2);
//        System.out.println(p1.value);
//        for(Integer v : p1.versions.values())
//            System.out.println(v);
//
//        // Test for merkle tree synchronization
//        // TODO: not finished
//        MerkleTree t1 = new MerkleTree(2, 0);
//        MerkleTree t2 = new MerkleTree(2, 0);
//        for(int i=0; i<3; i++){
//            t1.add(new KVPair(i+"", i+"", new HashMap<>()));
//        }
//        for(int i=0; i<9; i++){
//            t2.add(new KVPair(i+"", i+"", new HashMap<>()));
//        }
//        t1.print();
//        t2.print();
//        t1.synchroize(t2);
//
//        t1.print();



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




