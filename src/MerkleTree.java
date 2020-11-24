import java.util.LinkedList;
import java.util.Queue;

public class MerkleTree {
    int hash; // remember calculate both value and key
    MerkleTree left = null;
    MerkleTree right = null;
    MerkleTree parent = null;
    int height = 1;
    int num = 0; // total number of valid leaves in this root

    public MerkleTree(MerkleTree tree) {
        this.hash = tree.hash;
        this.left = tree.left;
        this.right = tree.right;
        this.parent = tree.parent;
        this.height = tree.height;
        this.num = tree.num;
    }

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

    public int add(LeafNode leaf){
        // if current merkle tree needs to be enlarged
        if( num == Math.pow(2, height-1)){
            MerkleTree temp = new MerkleTree(this);
            left = temp;
            right = new MerkleTree(height, 0);
            left.parent = this; right.parent = this;
            height += 1;
            hash = left.hash + right.hash;
        }

        // reach the last non leaf layer
        if(height == 2){
            leaf.parent = this;
            if(num == 0)
                left = leaf;
            else
                right = leaf;

            num++;

            // Update hash and return
            int hash_left = left == null ? 0 : left.hash;
            int hash_right = right == null ? 0 : right.hash;
            long temp = (hash_left + hash_right) % Integer.MAX_VALUE;
//            System.out.println("Hash left: "+hash_left +", hash right:" +hash_right);
            hash = (int) temp;

            return hash;
        }else if(num < Math.pow(2, height-1)){
            long temp = 0;
            if(num < Math.pow(2, height - 2)){
                temp += left.add(leaf);
                temp += right.hash;
            }else{
                temp += right.add(leaf);
                temp += left.hash;
            }
            num++;

            // Update hash and return
            hash = (int) temp;
            return hash;

        }else{
            System.out.println("Adding exception happens when adding elements to merkle tree");
            return -1;
        }
    }

    public void print(){
        Queue<MerkleTree> queue = new LinkedList<>();
        queue.add(this);
        while(!queue.isEmpty()){
            int size = queue.size();

            while(size > 0){
                size--;
//                System.out.println("size:" + size);
                MerkleTree tree = queue.poll();
                if(tree == null)
                    continue;
                if(height == 1){
                    LeafNode temp = (LeafNode) tree;
                    System.out.print("Key:"+temp.key+", Value:"+temp.value+", Version:"+temp.version);
                }else{
                    System.out.print(tree.hash+", ");
                    queue.add(tree.left); queue.add(tree.right);
                }


            }
            System.out.println("");
        }
    }

    static class LeafNode extends MerkleTree{
        String key;
        String value;
        int version;

        public LeafNode(String key, String value, int version) {
            super(1, 0);
            this.key = key;
            this.value = value;
            this.version = version;
            this.hash = version;
        }
    }

    class NonLeafNode extends MerkleTree{
        int hash;

        public NonLeafNode(int hash) {
            super(2, 0);
            this.hash = hash;
        }
    }
}


