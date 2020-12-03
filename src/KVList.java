import util.Pair;
import java.util.LinkedHashMap;
import java.util.List;

public class KVList {
    // Map<key, <value, version id>>
    private LinkedHashMap<String, Pair<String, Integer>> list;
//    public Map<Integer, String> key_to_hash;
    //private LinkedHashMap<Integer, String> index_to_key; //ADD index to key so that we know the order of the map

    public KVList() {
        this.list = new LinkedHashMap<>();
        //this.index_to_key = new HashMap<>();
//        this.hash_to_key = new HashMap<>();
    }

    public Boolean add(String key, String value, int other_version) {
        // TODO(NOT HERE): compare hash of both value and key so that the merkle tree can work correctly
        if (list.containsKey(key)) {
            int version = list.get(key).second();
            if (version < other_version) {
                list.put(key, new Pair(value, version));
            } else return false;
        } else {
            int version = 1;
            list.put(key, new Pair(value, version));
        }
        return true;

    }

    private void update(List<KVPair> updated) {
        for (KVPair p : updated)
            list.put(p.key, new Pair(p.value, p.version));
    }

    private int getHash(String key, Pair<String, Integer> pair){
        long hash = (key.hashCode() + pair.hashCode()) % Integer.MAX_VALUE;
        return (int) hash;
    }

    public String getValue(String key) {
        return this.list.get(key).first();
    }

    public int getVersion(String key) {
        return this.list.get(key).second();
    }

    public LinkedHashMap<String, Pair<String, Integer>> getContent() {
        return this.list;
    }
}
