import util.Pair;

import java.util.HashMap;
import java.util.Map;

public class KVPair {
    String key;
    String value;
    int maxVersion = -1;
    Map<Worker, Integer> versions = new HashMap<>();

    public KVPair(String key, String value, Map<Worker, Integer> versions) {
        this.key = key;
        this.value = value;
        this.versions = versions;
        setMaxVersion();
    }

    public void update(String key, String value, Worker worker, int version){
        if(!this.key.equals(key))
            System.out.println("Add Version Error: Key not match!");

        // Check whether this version > max_version
        if (version > maxVersion){
            this.value = value;
            maxVersion = version;
        }

        // Update the version of worker
        versions.put(worker, version);
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

    private void setMaxVersion(){
        for(Integer v : versions.values())
            maxVersion = Math.max(v, maxVersion);
    }
}
