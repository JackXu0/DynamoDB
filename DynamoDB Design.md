## DynamoDB

#### Ring (Partition):

- Hash key first, assign to a value range
- Each node is responsible for the region in the ring between it and its predecessor node on the ring.
- Assign two virtual nodes for each physical node

#### Replication:

- Hash the key, find the coordinator node, store key and value
- Replicate on N-1 clockwise nodes

#### Timestamp (Data versioning):

- Use vector time
- For each key value object $$D_i$$, make a list to store the latest value on each node and the last operating timestamp

#### Get and Put:

- Solution1: Using load balancer
  - send request to a random node
  - node broadcast to the request to the coordinator
- Solution2: Client knows the partition information
  - client send request to the coordinator
- If one of nodes is down, find the next healthy node
- Need to wait for R/W replicas before returning to client

#### Handling Failure (Hinted Handoff):

- If node X is supposed to handle the current message, but is down
- Will find a replacement node Y to handle this message
- Record in Y that this message is owned by X
- Scan periodically. If X is back, move this message to X

#### Handle permanet failures (Merkel tree):

- Our design:
  - N merkel tree for each virtual node
  - When sychronize, send the last merkel tree to the following N-1 virtual nodes

#### Ring membership:

- Maintain membership change history in storage
- reconcile with a random peer every second
- Once a node is up, it is mapped to a set of tokens (virtual node). Reconcile mapping info together with membership info

#### Failure Detection:

- Keep sychronizing members info with other nodes 
- If coordinator node X is down, move the request to the next node Y
- Record in Y that this message is owned by X
- Scan periodically. If X is back, move this message to X

#### Adding nodes:

- Find a place to insert new node
- If any node will be no longer responsible a value range, move records associated with this value range to the new node, after confirming with the new node.

#### Removing nodes:

- Remove the node
- Some nodes will be newly responsible for some value range. Move related data to each node.