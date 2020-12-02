import util.Pair;

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

    // TODO: PROBLEM: map is not sorted, need sorted container to rebuild
    public void rebuildMerkleTree(Map<Integer, String> index_to_key,
                                  Map<String, Pair<String, Integer>> storage) {
        //this.hash;
        if (index_to_key.size() == 0)
            return;

        this.left = null;
        this.right = null;
        this.parent = null;
        this.buffer = new HashMap<>();
        this.height = 1;
        this.num = 1;
        String key = index_to_key.get(1);
        Pair<String, Integer> info = storage.get(key);
        this.pair = new KVPair(key, info.first(), info.second());
        int index = 2;
        while(index_to_key.containsKey(index)) {
            key = index_to_key.get(index);
            info = storage.get(key);
            this.add(new KVPair(key, info.first(), info.second()), index);
            index++;
        }
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
        if( num >= Math.pow(2, height-1)){
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
//            System.out.println("left pair"+tree.left.pair.key+","+tree.left.pair.value+","+tree.left.pair.version);
//            if (tree.right.pair != null)
//                System.out.println("right pair"+tree.right.pair.key+","+tree.right.pair.value+","+tree.right.pair.version);
            int hash_left = (tree.left.pair == null ? 0 : tree.left.pair.version);
            int hash_right = (tree.right.pair == null ? 0 : tree.right.pair.version);

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

    public Pair<Boolean, List<KVPair>> synchroize(MerkleTree t2){
        List<KVPair> res = new ArrayList<>();

        //TODO: apply changes in res
        Boolean send = synchronize_helper(this, t2, res).first();
        return new Pair(send, res);
    }

    private Pair<Boolean, Integer> synchronize_helper(MerkleTree t1, MerkleTree t2, List<KVPair> res){
        Boolean send = false;
        if(t1.height > t2.height)
            return synchronize_helper(t1.left, t2, res);
        else if(t1.height < t2.height) {
            //System.out.println("t1 height: " + t1.height + ", t2.height: " + t2.height);
            //t1.print();
            t1.num = t2.num;
            //System.out.println(""+t1.num + " " +t2.num);
            t1.enlargeIfNecessary();
            //System.out.println("T1 after enlarge: ");
            //t1.print();
            return synchronize_helper(t1, t2, res);
        }
        if(t1.height == 1){
            KVPair p1 = t1.pair;
            KVPair p2 = t2.pair;
            if (p2 != null) {
                if (p1 == null) {
                    t1.pair = new KVPair(p2);
                    res.add(t1.pair);
                    t1.hash = t1.pair.getHash();
                    return new Pair<>(false, t1.pair.getHash());
                  //give p1 value
                } else {
                    if (!p1.key.equals(p2.key)) {
                        System.out.println("Key Not Match: P1 Key: " + p1.key + ", P2 Ley: " + p2.key);
                        return new Pair<>(false, p1.getHash());
                    }

                    if (p1.version < p2.version) {
                        p1.value = p2.value;
                        p1.version = p2.version;
                        res.add(p1);
                        return new Pair<>(false, p1.getHash());
                    } else if (p1.version > p2.version) {
                        return new Pair<>(true, p1.getHash());
                    } else {
                        System.out.println("same version with different values");
                        return new Pair<>(false, p1.getHash());
                    }
                }
            }
            return new Pair<>(false, t1.hash);
        }

        if(t1.hash == t2.hash)
            return new Pair<>(false, t1.hash);
        Pair<Boolean, Integer> left = synchronize_helper(t1.left, t2.left, res);
        Pair<Boolean, Integer> right = synchronize_helper(t1.right, t2.right, res);
        // TODO: add calculate hash
        t1.hash = left.second() + right.second();
        return new Pair<>(left.first() || right.first(), t1.hash);
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
                    System.out.print("Key:"+tree.pair.key+", Value:"+tree.pair.value+", version:"+tree.pair.version+", ");
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


