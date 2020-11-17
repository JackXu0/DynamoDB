import java.util.*;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.ArrayBlockingQueue;

/*
public class ThreadTest {
    public static class MyThread extends Thread {
        public void run() {
            System.out.println("Hello");
        }
    }

    public static void main(String[] args) {
        MyThread thread = new MyThread();
        thread.start();
    }
}
*/
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
    final String msg;

    // A message to a worker.
    public Message(String msg) {
        this.msg = msg;
    }

    public String toString() {
        return msg;
    }

}

class Worker implements Runnable {
    private volatile boolean stop = false;
    private final BlockingQueue<Message> workQueue;

    public Worker(BlockingQueue<Message> workQueue) {
        this.workQueue = workQueue;
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