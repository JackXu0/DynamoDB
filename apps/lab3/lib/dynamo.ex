defmodule Dynamo do

  import Emulation, only: [send: 2, timer: 1, now: 0, whoami: 0]

  import Kernel,
    except: [spawn: 3, spawn: 1, spawn_link: 1, spawn_link: 3, send: 2]

  require Fuzzers
  require Logger

  # define constructor for the worker
  defstruct(
    # List to store menbership changing history
    menbership_changing_history: nil,
    # Virtual Node Ring
    virtual_node_ring: nil,
    # # Name of this worker
    # name: nil,
    # configurations
    num_partition: nil,
    r: nil,
    w: nil,
    is_seed: nil,
    # store the status for each worker node
    worker_map: nil,
    # store the reference of the seed worker
    seed_worker: nil,
    # store all virtual nodes
    virtual_nodes: nil,
    # store all merkle trees
    merkle_trees: nil,
    # store all KVPairs
    storage: nil,
    # the status of this worker
    is_running: nil,

  )

  @doc """
  Create state for an initial Raft cluster. Each
  process should get an appropriately updated version
  of this state.
  """
  @spec new_configuration(
          atom(),
          non_neg_integer(),
          non_neg_integer(),
          non_neg_integer()
        ) :: %Dynamo{}
  def new_configuration(
        seed_worker,
        num_partition,
        r,
        w
      ) do
    %Dynamo{
      menbership_changing_history: [],
      # TODO: implement a virtual node ring module
      virtual_node_ring: %Dynamo.VirtualNodeRing{},
      num_partition: num_partition,
      r: r,
      w: w,
    }
  end

  # # Enqueue an item, this **modifies** the state
  # # machine, and should only be called when a log
  # # entry is committed.
  # @spec enqueue(%Raft{}, any()) :: %Raft{}
  # defp enqueue(state, item) do
  #   %{state | queue: :queue.in(item, state.queue)}
  # end

  def test() do
    virtual_node_ring = %Dynamo.VirtualNodeRing{}
    IO.puts(111)
    # vn1 = %Dynamo.VirtualNode{worker: :a, hash: :hjkafaf, partition: 0}
    vn1 = Dynamo.VirtualNode.new(:a, :hjkafaf, 0)
    IO.puts(222)
    virtual_node_ring = Dynamo.VirtualNodeRing.put(virtual_node_ring, vn1)
    IO.puts(333)
    
    
    vn2 = Dynamo.VirtualNode.new(:a, :hash2, 0)
    vn3 = Dynamo.VirtualNode.new(:a, :hash3, 0)
    
    virtual_node_ring = Dynamo.VirtualNodeRing.put(virtual_node_ring, vn2)
    virtual_node_ring = Dynamo.VirtualNodeRing.put(virtual_node_ring, vn3)

    IO.inspect(virtual_node_ring.ring)

  end

end