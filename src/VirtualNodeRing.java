import java.util.Iterator;
import java.util.Map;
import java.util.SortedMap;

public class VirtualNodeRing{
    SortedMap<String, VirtualNode> virtual_nodes_ring;

    public VirtualNodeRing(SortedMap<String, VirtualNode> virtual_nodes_ring) {
        this.virtual_nodes_ring = virtual_nodes_ring;
    }

    public VirtualNode getCoordinatorNode(String hash){
        for(Map.Entry<String, VirtualNode> entry : virtual_nodes_ring.entrySet()){
            if(entry.getKey().compareTo(hash) > 0)
                return entry.getValue();
        }

        return virtual_nodes_ring.get(virtual_nodes_ring.firstKey());
    }

    public void put(VirtualNode vn){
        this.virtual_nodes_ring.put(vn.hash, vn);
    }

    public String[] getVirtualNodeHashArray(){
        return (String[]) virtual_nodes_ring.keySet().toArray();
    }
}
