public class VirtualNode {
    Worker worker;
    int hash;
    int partition;

    //TODO: add previous virtual node field  (abort?)
    //TODO: add previous virtual node hash field (abort?)

    public VirtualNode(Worker worker, int hash, int partition){
        this.worker = worker;
        this.hash = hash;
        this.partition = partition;
    }
}
