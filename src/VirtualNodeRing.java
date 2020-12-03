import java.util.Iterator;
import java.util.Map;
import java.util.SortedMap;

public class VirtualNodeRing{
    SortedMap<Integer, VirtualNode> virtual_nodes_ring;

    public VirtualNodeRing(SortedMap<Integer, VirtualNode> virtual_nodes_ring) {
        this.virtual_nodes_ring = virtual_nodes_ring;
    }

    public VirtualNode getCoordinatorNode(int hash){
        for(Map.Entry<Integer, VirtualNode> entry : virtual_nodes_ring.entrySet()){
            if(entry.getKey() > hash)
                return entry.getValue();
        }

        return virtual_nodes_ring.get(virtual_nodes_ring.firstKey());
    }

    public void put(VirtualNode vn){
        this.virtual_nodes_ring.put(vn.hash, vn);
    }
}
