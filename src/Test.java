import java.util.*;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.ArrayList;
import java.util.Random;

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

class KV {
    private String key;
    private String value;
    private ArrayList<Pair<Worker, Integer>> timestamp;
}

class VirtualNode {
    Worker worker;
    int hash;
    int partition;
    ArrayList<KV> storage;

    public VirtualNode(Worker worker, int hash, int parttiton){
        this.worker = worker;
        this.hash = hash;
        this.partition = parttiton;
        this.storage = new ArrayList<>();
    }

}

class Worker implements Runnable {
    private boolean stop = false;
    private final BlockingQueue<Message> workQueue;
    private ArrayList<VirtualNode> VNs;

    public Worker(BlockingQueue<Message> workQueue, Integer num_partition, Master ) {
        this.workQueue = workQueue;
        this.VNs = new ArrayList();
        int partition = 0;
        while (num_partition > 0) {
            Random rand = new Random();
            Integer hash = rand.nextInt();
            VirtualNode VN = new VirtualNode(this, hash, num_partition);
            this.VNs.add(VN);

        }
    }

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
            Worker worker = this.VN_to_worker.get(hashcode).First();
            Integer VN_partition = this.VN_to_worker.get(hashcode).Second();
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

        public T1 First() {
            return this.first;
        }

        public T2 Second() {
            return this.second;
        }
    }
}


