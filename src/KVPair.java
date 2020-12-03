import util.Pair;

import java.util.HashMap;
import java.util.Map;

public class KVPair {
    String key;
    String value;
    int version;

    public KVPair(String key, String value, int version) {
        this.key = key;
        this.value = value;
        this.version = version;
    }

    public KVPair(KVPair p2) {
        this.key = p2.key;
        this.value = p2.value;
        this.version = p2.version;
    }


    public String getHash(){
        return Util.getMD5(key + value + version);
    }

    /*
    public void update(String key, String value, int version){
        if(!this.key.equals(key))
            System.out.println("Add Version Error: Key not match!");

        // Check whether this version > max_version


        // Update the version of worker
        this.version = version;


    }

    public void update(KVPair p2){
        for(Map.Entry<Worker, Integer> v : p2.versions.entrySet()){
            int worker_version_local = versions.get(v.getKey());
            int worker_version_p2 = v.getValue();
            if(worker_version_p2 > maxVersion){
                maxVersion = worker_version_p2;
                value = p2.value;
            }
            versions.put(v.getKey(), Math.max(worker_version_local, worker_version_p2));
        }
    }
    */
}
