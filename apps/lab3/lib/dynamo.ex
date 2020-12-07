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
    name: nil,
    # configurations
    p: nil,
    n: nil,
    r: nil,
    w: nil,
    is_seed: nil,
    # store the status for each worker node
    view: nil,
    # store the reference of the seed worker
    seed_worker: nil,
    # store all virtual nodes
    virtual_nodes: nil,
    # store all merkle trees
    merkle_trees: nil,
    # store all KVPairs
    storage: %{},
    # the status of this worker
    is_running: :true,
    # the hash of this worker
    hash: nil,
    worker_map: nil,
    put_map: %{},
    get_map: %{},
    key_versions: %{}

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
          non_neg_integer(),
          non_neg_integer()
        ) :: %Dynamo{}
  def new_configuration(
        seed_worker,
        p,
        n,
        r,
        w
      ) do
    %Dynamo{
      #menbership_changing_history: [],
      # TODO: implement a virtual node ring module
      virtual_node_ring: elem(ExHashRing.Ring.start_link(), 1),
      p: p,
      n: n,
      r: r,
      w: w,
      name: nil,
      view: %{},
      merkle_trees: nil,
    }
  end

  @spec broadcast_to_others(%Dynamo{}, any()) :: [boolean()]
  defp broadcast_to_others(state, message) do
    me = whoami()
    IO.inspect(state.view)

    filtered = :maps.filter fn name, pid -> name != state.name end, state.view
    IO.puts("filtered #{inspect(filtered)}")
    IO.puts("new worker to be added is #{inspect(message.worker)}")
    Enum.each Map.values(filtered), fn pid -> send(pid, message) end
  end



  @spec become_worker(%Dynamo{}, atom()) :: no_return()
  def become_worker(state, name) do
    # TODO: Do anything you need to when a process
    # transitions to a follower.
    # state.merkle_trees = [MapSet.new()]
    %{state | merkle_trees:  [MapSet.new()]}

    IO.puts(" #{inspect(whoami())} became worker")
    # assign name
    state = %{state | name:  name}

    # add self to view
    state = addWorker(state, name, whoami())

    # # calculate hash for itself
    # state = %{state | hash:  Enum.random(1..1_000)}
    

    # add to ring
    broadcast_to_others(state, %Dynamo.AddWorkerRequest{worker: whoami(), worker_name: state.name})


    worker(state)
  end

  @spec worker(%Dynamo{}) :: no_return()
  def worker(state) do
    IO.puts("#{inspect(whoami())} is waiting for msg.")
    receive do
      {sender,
        :getConfig
        } ->
          send(sender, state)
          worker(state)

      # {sender,
      #   %Dynamo.AddVirtualNodeRequest{
      #     worker: worker,
      #     worker_name: worker_name
      #   }} ->
      #    # TODO: Handle an AppendEntryRequest received by a
      #    # follower
      #    IO.puts("Add Virtual Node -- #{inspect(whoami())} is going to add virtual node #{inspect(worker)} with worker_name #{worker_name}")
      #    state = addVirtualNodes(state, worker_name)
         
      #    IO.puts("Add Virtual Node -- virtual node ring after insertion #{inspect(state.virtual_node_ring)}")
      #    worker(state)

      {sender,
         %Dynamo.AddWorkerRequest{
           worker: worker,
           worker_name: worker_name
         }} ->
          # TODO: Handle an AppendEntryRequest received by a
          # follower
          IO.puts("#{inspect(whoami())} knows that it needs to add #{inspect(worker)}")
          IO.puts("Add Worker -- #{inspect(whoami())} is going to add worker #{inspect(worker)}")
          state = addWorker(state, worker_name, worker)
          IO.puts("Add Worker -- View aftering inserting this worker: #{inspect(state.view)}")
          #IO.puts("#{inspect(state)}")
          worker(state)

          
      {sender,
          %Dynamo.PutRequestFromClient{
            key: key,
            value: value
          }} ->
           IO.puts("#{inspect(sender)}")
           IO.puts("Put Request From Client-- #{inspect(whoami())} received put request key: #{key} value: #{value}")
           coordinate_worker = getCoordinatorWorker(state, key)
           IO.puts("#{inspect(whoami())} will send the request to the coordinator #{inspect(coordinate_worker)}")
           send(coordinate_worker, %Dynamo.PutRequestToCoordinateNode{
                                                client: sender,
                                                key: key,
                                                value: value
                                              })
           worker(state)

      {sender,
           %Dynamo.PutRequestToCoordinateNode{
             client: client,
             key: key,
             value: value
           }} ->
            IO.puts("Put Request to Coordinator Node -- #{inspect(whoami())} received put request key: #{key} value: #{value}")
            state = %{state | storage:  Map.put(state.storage, key, value)}
            version = if state.key_versions[key] == nil do
                        1
                      else
                        state.key_versions[key] + 1
                      end
            state = %{state | key_versions:  Map.put(state.key_versions, key, version)}
            state = %{state | put_map:  Map.put(state.put_map, get_hash("put #{key}: #{value}"), 1)}
            replica_workers = getReplicaWorker(state, key)
            IO.puts("Get replica workers #{inspect(replica_workers)}")

            Enum.each replica_workers, fn pid ->
              send(pid, %Dynamo.PutRequestToReplicaNode{
                            client: client,
                            key: key,
                            value: value,
                            version: state.key_versions[key]
                          })
            end

            if state.w == 1 do
              IO.puts("ACK")
              send(client, :ok)
            end
            # state = %{state | storage:  Map.put(state.storage, key, value)}
            worker(state)

      {sender,
            %Dynamo.PutRequestToReplicaNode{
              client: client,
              key: key,
              value: value,
              version: version
            }} ->
              # TODO: Handle an AppendEntryRequest received by a
              # follower
              IO.puts("Put Request to Replica Node -- #{inspect(whoami())} received put request key: #{key} value: #{value}")
              if state.key_versions[key] == nil or version >= state.key_versions[key] do
                state = %{state | storage:  Map.put(state.storage, key, value)}
                state = %{state | key_versions:  Map.put(state.key_versions, key, version)}
                send(sender,  %Dynamo.PutResponseToCoordinator{
                            client: client,
                            key: key,
                            value: value
                          })
                IO.puts("#{whoami()} done sending to coordinator")
                worker(state)
              else
                IO.puts("Receive old version request on #{inspect(whoami())}")
                worker(state)
              end
              

      {sender,
              %Dynamo.PutResponseToCoordinator{
                client: client,
                key: key,
                value: value
              }} ->
                # TODO: Handle an AppendEntryRequest received by a
                # follower
                IO.puts("Put Response to Coordinator Node -- #{inspect(whoami())} received put request key: #{key} value: #{value} from #{sender}")
                hash = get_hash("put #{key}: #{value}")
                {_, value} = Map.fetch(state.put_map, hash)
                value = value + 1
                state = %{state | put_map:  Map.put(state.put_map, hash, value)}
                if value == state.w do
                  IO.puts("ACK")
                  send(client, :ok)
                end

                state = if value == state.n do
                  %{state | put_map:  Map.delete(state.put_map, hash)}
                else 
                  state
                end

                worker(state)

      {sender,
              %Dynamo.GetRequestFromClient{
                key: key
              }} ->
                IO.puts("Received get request from client -- key: #{key}")
                state = %{state | get_map:  Map.put(state.get_map, key, [])}
                workers = getReplicaWorker(state, key)
                # IO.puts("workers #{inspect(workers)}")
                Enum.each workers, fn pid ->
                  send(pid, %Dynamo.GetRequestToWorkers{
                                client: sender,
                                key: key
                              })
                  end
                worker(state)

      
      {sender,
              %Dynamo.GetRequestToWorkers{
                client: client,
                key: key
              }} ->
                # TODO: Handle an AppendEntryRequest received by a
                # follower
                IO.puts("workers #{inspect(whoami())} received get request-- key: #{key}")
                version = if state.key_versions[key] == nil do
                  -1
                else
                  state.key_versions[key]
                end
                send(sender,  %Dynamo.GetResponseFromWorkers{
                                client: client,
                                key: key,
                                value: state.storage[key],
                                version: version
                              })
                worker(state)

      {sender,
                %Dynamo.GetResponseFromWorkers{
                  client: client,
                  key: key,
                  value: value,
                  version: version
                }} ->
                  # TODO: Handle an AppendEntryRequest received by a
                  # follower
                  IO.puts("received get response from worker #{inspect(sender)} -- key: #{key} value: #{value}, version: #{version}")
                  if state.get_map[key] != nil do
                    state = %{state | get_map:  Map.put(state.get_map, key, state.get_map[key] ++ [{value, version}])}
                    IO.puts("Get map length #{length(state.get_map[key])}")
                    if length(state.get_map[key]) == state.r do
                      values = state.get_map[key]
                      # remove nil versions
                      # values = values
                      #           |> Enum.filter(fn {value, version} -> version != nil end)
                      # if length(values) == 0 do
                      #   send(client,  %Dynamo.GetResponseToClient{
                      #     key: key,
                      #     value: nil
                      #   })
                      #   worker(state)
                      # end
                      # sort by version
                      values = values |> Enum.sort_by(&(elem(&1, 1)))
                      IO.puts("values #{inspect(values)}")
                      send(client,  %Dynamo.GetResponseToClient{
                        key: key,
                        value: elem(List.last(values), 0)
                      })
                      state = %{state | get_map:  Map.delete(state.get_map, key)}
                      worker(state)
                    end
                    
                    worker(state)
                    
                  else
                    worker(state)
                  end
                  
                  

      
    end
  end

  # @spec getCoordinatorNode(%Dynamo{}, atom()) :: %Dynamo{}
  # def getCoordinatorNode(state, hash) do
  #   virtual_node_ring = state.virtual_node_ring
  #   candidate_coordinator_node = getCoordinatorNodeHelper(virtual_node_ring, hash)
  #   if candidate_coordinator_node == nil do
  #     List.first(virtual_node_ring)
  #   else
  #     candidate_coordinator_node
  #   end
  # end

  # @spec getCoordinatorNodeHelper(list(any()), atom()) :: any()
  # def getCoordinatorNodeHelper(ring, hash) do
  #   # IO.inspect(ring)
  #   if Enum.count(ring) == 0 do
  #     nil
  #   end
  #   [head | tail] = ring
  #   # IO.inspect(head)
  #   # IO.inspect(hash)
  #   # IO.inspect(elem(head, 0))
  #   # IO.inspect(hash < elem(head, 0))
  #   if hash < elem(head, 0) do
  #     head
  #   else
  #     getCoordinatorNodeHelper(tail, hash)
  #   end
  # end

  # @spec addVirtualNode(%Dynamo{}, atom(), %Dynamo{}) :: %Dynamo{}
  # def addVirtualNode(state, hash, worker) do
  #   # %{state | ring:  Map.put(state.ring, 1, 1)}
  #   %{state | virtual_node_ring:  Enum.concat(state.virtual_node_ring, [{hash, worker}])}
  # end

  @spec get_hash(atom()) :: atom()
  defp get_hash(key) do
    :crypto.hash(:md5 , key) |> Base.encode16()
  end

  #@spec addVirtualNodes(%Dynamo{}, atom()) :: %Dynamo{}
  #def addVirtualNodes(state, worker_name) do
    # %{state | ring:  Map.put(state.ring, 1, 1)}
    # %{state | virtual_node_ring:  elem(ExHashRing.Ring.add_node(state.virtual_node_ring, worker_name, 10), 1)}
  #  ExHashRing.Ring.add_node(state.virtual_node_ring, worker_name, state.p)
  #  state
  #end

  @spec addWorker(%Dynamo{}, atom(), %Dynamo{}) :: %Dynamo{}
  def addWorker(state, name, worker) do
    addVirtualNodeHelper(state, name, state.p)
    %{state | view:  Map.put(state.view, name, worker)}
  end

  def addVirtualNodeHelper(state, worker_name, p) do
    if p > 0 do
      #IO.puts("adding vn, partition: #{worker_name}#{p}")
      ExHashRing.Ring.add_node(state.virtual_node_ring, "#{worker_name}#{p}", 1)
      addVirtualNodeHelper(state, worker_name, p-1)
    end
  end

  @spec getCoordinatorWorker(%Dynamo{}, atom()) :: %Dynamo{}
  def getCoordinatorWorker(state, key) do
    IO.puts("current ring #{inspect(state.virtual_node_ring)}")
    IO.puts("key is #{key}")
    {_, name} = ExHashRing.Ring.find_node(state.virtual_node_ring, key)
    IO.puts("VN name is #{inspect(name)}")
    IO.puts("#{inspect(state.view)}")
    coordinator_name = String.slice(name, 0..-2)
    {_, worker} = Map.fetch(state.view, coordinator_name)
    IO.puts("coordinator worker is #{inspect(worker)}")
    worker
  end

  @spec getConfig(%Dynamo{}) :: %Dynamo{}
  def getConfig(state) do
    state
  end


  def trim(list, accumulator) do
    if list == [] do
        accumulator
    else
        [head | tail] = list
        #name = String.slice(head, 0..-2)
        #IO.puts("#{inspect(name)}")
        trim(tail, accumulator ++ [String.slice(head, 0..-2)])
    end
  end


  @spec getReplicaWorker(%Dynamo{}, atom()) :: {%Dynamo{}}
  def getReplicaWorker(state, key) do
    {_, [head | tail]} = ExHashRing.Ring.find_nodes(state.virtual_node_ring, key, state.n)
    IO.puts("getting vn names")
    tail = trim(tail, [])
    IO.puts("#{inspect(tail)}")
    res = :maps.filter fn vn_name, vn -> name = Enum.member?(tail, vn_name) end, state.view
    Map.values(res)
  end

  @spec getAllWorkers(%Dynamo{}, atom()) :: {%Dynamo{}}
  def getAllWorkers(state, key) do
    {_, list} = ExHashRing.Ring.find_nodes(state.virtual_node_ring, key, state.n)
    res = :maps.filter fn worker_name, worker -> Enum.member?(list, worker_name) end, state.view
  end


  # def make_seed(state) do
    
  # end


  # @spec put(%Dynamo{}, atom(), atom()) :: %Dynamo{}
  # def put(state, key, value) do
  #   coordinator_node = Dynamo.VirtualNodeRing.getCoordinatorNode(state.virtual_node_ring)
  #   coordinator_node.put()
  # end

end