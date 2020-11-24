import java.util.ArrayList;

public class Message {
    // 0 means put
    // 1 means get
    // TODO: add more
    int type;
    String key;
    String value;
    long timestamp = -1;
    Message response_message;

    // Client send to worker PUT
    public Message(int type, String key, String value) {
        this.type = type;
        this.key = key;
        this.value = value;
    }

    // Client send to worker GET
    public Message(int type, String key) {
        this.type = type;
        this.key = key;
    }

    // worker to worker
    public Message(int type, String key, String value, long timestamp) {
        this.type = type;
        this.key = key;
        this.value = value;
        this.timestamp = timestamp;
    }

    // Function as ACK
    public Message(Message msg){
        this.response_message = msg;
    }

}
