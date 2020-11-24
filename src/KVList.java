import util.Pair;

import java.util.HashMap;
import java.util.Map;

public class KVList {
    // Map<key, <value, version id>>
    private Map<String, Pair<String, Map<Worker, Integer>>> list;
//    public Map<Integer, String> key_to_hash;

    public KVList() {
        this.list = new HashMap<>();
//        this.hash_to_key = new HashMap<>();
    }

    public void add(String key, String value, Worker worker) {
        // TODO(NOT HERE): compare hash of both value and key so that the merkle tree can work correctly
        if (list.containsKey(key)) {
            Map<Worker, Integer> version = list.get(key).second();
            version.put(worker, version.getOrDefault(worker, 0) + 1);
        } else {
            Map<Worker, Integer> version = new HashMap<>();
            version.put(worker, 1);
            list.put(key, new Pair(value, version));
        }

    }

    private int getHash(String key, Pair<String, Map<Worker, Integer>> pair){
        long hash = (key.hashCode() + pair.hashCode()) % Integer.MAX_VALUE;
        return (int) hash;
    }

    public String getValue(String key) {
        return this.list.get(key).first();
    }

    public Map<Worker, Integer> getVersions(String key) {
        return this.list.get(key).second();
    }
}
