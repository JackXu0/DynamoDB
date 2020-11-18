import java.util.*;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.ArrayList;
import java.util.Dictionary;
import javafx.util.Pair;

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

    Pair<Integer, Integer> pair = new Pair();

}

class Message {
    final String msg;

    // A message to a worker.
    public Message(String msg) {
        this.msg = msg;
    }

    public String toString() {
        return msg;
    }

}

class VirtualNode {

}

class Worker implements Runnable {
    private boolean stop = false;
    private final BlockingQueue<Message> workQueue;
    private ArrayList Storage;
    private String ip;

    public Worker(BlockingQueue<Message> workQueue) {
        this.workQueue = workQueue;
        // later add support to different num of partitions
        HashMap<String,String> virtualNode1 = new HashMap<String,String>();
        HashMap<String,String> virtualNode2 = new HashMap<String,String>();
        this.Storage = new ArrayList();
        this.Storage.add(virtualNode1);
        this.Storage.add(virtualNode2);
        this.ip = Util.getRandomIP();
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
            //(worker, VN_partition) = this.VN_to_worker.get(hashcode);
            //worker.store(VN_partition, message)
            hashcode++;
            if (hashcode >= num_VN) {
                hashcode = hashcode % num_VN;
                turn_around = false;
            }
        }
    }

    private Pair<Worker, Integer> getLoc(Pair<String, String> message) {
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
}


