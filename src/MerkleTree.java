import java.util.*;

//TODO: Add hash calculation
public class MerkleTree {
    int hash; // remember calculate both value and key
    MerkleTree left = null;
    MerkleTree right = null;
    MerkleTree parent = null;
    int height = 1;
    int num = 0; // total number of valid leaves in this root
    KVPair pair = null;
    Map<Integer, KVPair> buffer = new HashMap<>();

    // copy a merkle tree
    public MerkleTree(MerkleTree tree) {
        
        this.hash = tree.hash;
        this.left = tree.left;
        this.right = tree.right;
        this.left.parent = this;
        this.right.parent = this;
        this.parent = tree.parent;
        this.height = tree.height;
        this.num = tree.num;
    }

    // init a merkle tree with height and num
    public MerkleTree(int height, int num) {
        this.num = num;
        this.height = height;

        int h = height;
        // initialize tree
        Queue<MerkleTree> queue = new LinkedList<>();
        queue.add(this);
        while(h > 1){
            int size = queue.size();
            while(size > 0){
                size--;
                MerkleTree tree = queue.poll();
                tree.left = new MerkleTree(h-1, 0);
                tree.right = new MerkleTree(h-1, 0);
                queue.add(tree.left); queue.add(tree.right);
            }
            h--;
        }
    }

    //init a merkle tree with KVPair
    public MerkleTree(KVPair pair) {
        // TODO: add hash calculation
        this.height = 1;
        this.num = 1;
        this.pair = pair;
    }

    public void add(KVPair pair, Integer pos){
        // check whether the current merkle tree needs to be enlarged, enlarge if needed
        if (pos > num + 1 || pos <= num) {
            buffer.put(pos, pair);
            //////////////
            if (pos <= num)
                System.out.println("pos <= num");
            //////////////
            return;
        }

        enlargeIfNecessary();
        // add the key value pair to the merkle tree
        add_helper(this, pair);
        while (buffer.containsKey(num + 1)) {
            add(buffer.get(num+1), num+1);
            buffer.remove(num+1);
        }
    }

    public void enlargeIfNecessary(){
        if( num == Math.pow(2, height-1)){
            System.out.println("Needs enlarge");
            MerkleTree temp = new MerkleTree(this);
            this.left = temp;
            this.right = new MerkleTree(height, 0);
            this.left.parent = this; this.right.parent = this;
            this.height += 1;
            this.hash = this.left.hash + this.right.hash;
        }
    }

    private int add_helper(MerkleTree tree, KVPair pair){
        // reach the last non leaf layer
        if(tree.height == 2){
            MerkleTree leaf = new MerkleTree(pair);
            leaf.parent = tree;
            if(tree.num == 0)
                tree.left = leaf;
            else
                tree.right = leaf;

            tree.num++;
            // Update hash and return
            // TODO: add hash calculation
            int hash_left = (tree.left.pair == null ? 0 : 1);
            int hash_right = (tree.right.pair == null ? 0 : 1);

            long temp = (hash_left + hash_right) % Integer.MAX_VALUE;
//            System.out.println("temp:" + temp);
//            System.out.println("Hash left: "+hash_left +", hash right:" +hash_right);
            tree.hash = (int) temp;

            return tree.hash;
        }else if(tree.num < Math.pow(2, tree.height-1)){
            long temp = 0;
            if(tree.num < Math.pow(2, tree.height - 2)){
                temp += add_helper(tree.left, pair);
                temp += tree.right.hash;
            }else{
                temp += add_helper(tree.right, pair);
                temp += tree.left.hash;
            }
            tree.num++;

            // Update hash and return
            tree.hash = (int) temp;
//            System.out.println("temp:" + temp);
            return tree.hash;

        }else{
            System.out.println("Adding exception happens when adding elements to merkle tree");
            return -1;
        }
    }

    public void synchroize(MerkleTree t2){
        List<KVPair> res = new ArrayList<>();
        synchronize_helper(this, t2, res);
    }

    private void synchronize_helper(MerkleTree t1, MerkleTree t2, List<KVPair> res){
        if(t1.height > t2.height)
            synchronize_helper(t1.left, t2, res);
        else if(t1.height < t2.height)
            synchronize_helper(t1, t2.left, res);
        if(t1.height == 1){
            KVPair p1 = t1.pair;
            KVPair p2 = t2.pair;
            if(!p1.key.equals(p2.key)){
                System.out.println("Key Not Match: P1 Key: "+p1.key+", P2 Ley: "+p2.key);
            }else{
                p1.update(p2);
            }
            res.add(p1);
            return;
        }

        if(t1.hash == t2.hash)
            return;
        synchronize_helper(t1.left, t2.left, res);
        synchronize_helper(t1.right, t2.right, res);
    }

    public void print(){
        Queue<MerkleTree> queue = new LinkedList<>();
        queue.add(this);
        while(!queue.isEmpty()){
            int size = queue.size();
            while(size > 0){
                size--;
                MerkleTree tree = queue.poll();
                if(tree == null)
                    continue;
                if(tree.height == 1 && tree.pair != null){
                    System.out.print("Key:"+tree.pair.key+", Value:"+tree.pair.value+", ");
                }else if (height > 1){
                    System.out.print(tree.hash+", ");
                    queue.add(tree.left); queue.add(tree.right);
                }else{
                    System.out.println("Height:"+height);
                }


            }
            System.out.println("");
        }
    }

//    static class LeafNode extends MerkleTree{
//        String key;
//        String value;
//        int version;
//
//        public LeafNode(String key, String value, int version) {
//            super(1, 0);
//            this.key = key;
//            this.value = value;
//            this.version = version;
//            this.hash = version;
//        }
//    }
//
//    class NonLeafNode extends MerkleTree{
//        int hash;
//
//        public NonLeafNode(int hash) {
//            super(2, 0);
//            this.hash = hash;
//        }
//    }
}


