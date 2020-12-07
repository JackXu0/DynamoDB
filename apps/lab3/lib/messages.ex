defmodule Raft.LogEntry do
  @moduledoc """
  Log entry for Raft implementation.
  """
  alias __MODULE__
  @enforce_keys [:index, :term]
  defstruct(
    index: nil,
    term: nil,
    operation: nil,
    requester: nil,
    argument: nil
  )

  @doc """
  Return an empty log entry, this is mostly
  used for convenience.
  """
  @spec empty() :: %LogEntry{index: 0, term: 0}
  def empty do
    %LogEntry{index: 0, term: 0}
  end

  @doc """
  Return a nop entry for the given index.
  """
  @spec nop(non_neg_integer(), non_neg_integer(), atom()) :: %LogEntry{
          index: non_neg_integer(),
          term: non_neg_integer(),
          requester: atom() | pid(),
          operation: :nop,
          argument: none()
        }
  def nop(index, term, requester) do
    %LogEntry{
      index: index,
      term: term,
      requester: requester,
      operation: :nop,
      argument: nil
    }
  end

  @doc """
  Return a log entry for an `enqueue` operation.
  """
  @spec enqueue(non_neg_integer(), non_neg_integer(), atom(), any()) ::
          %LogEntry{
            index: non_neg_integer(),
            term: non_neg_integer(),
            requester: atom() | pid(),
            operation: :enq,
            argument: any()
          }
  def enqueue(index, term, requester, item) do
    %LogEntry{
      index: index,
      term: term,
      requester: requester,
      operation: :enq,
      argument: item
    }
  end

  @doc """
  Return a log entry for a `dequeue` operation.
  """
  @spec dequeue(non_neg_integer(), non_neg_integer(), atom()) :: %LogEntry{
          index: non_neg_integer(),
          term: non_neg_integer(),
          requester: atom() | pid(),
          operation: :enq,
          argument: none()
        }
  def dequeue(index, term, requester) do
    %LogEntry{
      index: index,
      term: term,
      requester: requester,
      operation: :deq,
      argument: nil
    }
  end
end

defmodule Raft.AppendEntryRequest do
  @moduledoc """
  AppendEntries RPC request.
  """
  alias __MODULE__

  # Require that any AppendEntryRequest contains
  # a :term, :leader_id, :prev_log_index, and :leader_commit_index.
  @enforce_keys [
    :term,
    :leader_id,
    :prev_log_index,
    :prev_log_term,
    :leader_commit_index
  ]
  defstruct(
    term: nil,
    leader_id: nil,
    prev_log_index: nil,
    prev_log_term: nil,
    entries: nil,
    leader_commit_index: nil
  )

  @doc """
  Create a new AppendEntryRequest
  """

  @spec new(
          non_neg_integer(),
          atom(),
          non_neg_integer(),
          non_neg_integer(),
          list(any()),
          non_neg_integer()
        ) ::
          %AppendEntryRequest{
            term: non_neg_integer(),
            leader_id: atom(),
            prev_log_index: non_neg_integer(),
            prev_log_term: non_neg_integer(),
            entries: list(any()),
            leader_commit_index: non_neg_integer()
          }
  def new(
        term,
        leader_id,
        prev_log_index,
        prev_log_term,
        entries,
        leader_commit_index
      ) do
    %AppendEntryRequest{
      term: term,
      leader_id: leader_id,
      prev_log_index: prev_log_index,
      prev_log_term: prev_log_term,
      entries: entries,
      leader_commit_index: leader_commit_index
    }
  end
end

defmodule Raft.AppendEntryResponse do
  @moduledoc """
  Response for the AppendEntryRequest
  """
  alias __MODULE__
  @enforce_keys [:term, :log_index, :success]
  defstruct(
    term: nil,
    # used to relate request with response.
    log_index: nil,
    success: nil
  )

  @doc """
  Create a new AppendEntryResponse.
  """
  @spec new(non_neg_integer(), non_neg_integer(), boolean()) ::
          %AppendEntryResponse{
            term: non_neg_integer(),
            log_index: non_neg_integer(),
            success: boolean()
          }
  def new(term, prevIndex, success) do
    %AppendEntryResponse{
      term: term,
      log_index: prevIndex,
      success: success
    }
  end
end

defmodule Raft.RequestVote do
  @moduledoc """
  Arguments when requestion votes.
  """
  alias __MODULE__
  @enforce_keys [:term, :candidate_id, :last_log_index, :last_log_term]
  defstruct(
    term: nil,
    candidate_id: nil,
    last_log_index: nil,
    last_log_term: nil
  )

  @doc """
  Create a new RequestVote request.
  """
  @spec new(non_neg_integer(), atom(), non_neg_integer(), non_neg_integer()) ::
          %RequestVote{
            term: non_neg_integer(),
            candidate_id: atom(),
            last_log_index: non_neg_integer(),
            last_log_term: non_neg_integer()
          }
  def new(term, id, last_log_index, last_log_term) do
    %RequestVote{
      term: term,
      candidate_id: id,
      last_log_index: last_log_index,
      last_log_term: last_log_term
    }
  end
end

defmodule Raft.RequestVoteResponse do
  @moduledoc """
  Response for RequestVote requests.
  """
  alias __MODULE__
  @enforce_keys [:term, :granted]
  defstruct(
    term: nil,
    granted: nil
  )

  @doc """
  Create a new RequestVoteResponse.
  """
  @spec new(non_neg_integer(), boolean()) ::
          %RequestVoteResponse{
            term: non_neg_integer(),
            granted: boolean()
          }
  def new(term, granted) do
    %RequestVoteResponse{term: term, granted: granted}
  end
end

defmodule Dynamo.HelloWorldRequest do
  @moduledoc """
  Response for RequestVote requests.
  """
  alias __MODULE__
  @enforce_keys [:msg]
  defstruct(
    msg: nil
  )

  @doc """
  Create a new RequestVoteResponse.
  """
  @spec new(atom()) ::
          %HelloWorldRequest{
            msg: atom()
          }
  def new(msg) do
    %HelloWorldRequest{msg: msg}
  end
end

defmodule Dynamo.Message do

  alias __MODULE__
  @enforce_keys [:msg]
  defstruct(
    msg: nil
  )

  @spec new(atom()) ::
          %Message{
            msg: atom()
          }
  def new(msg) do
    %Message{msg: msg}
  end
end

defmodule Dynamo.AddVirtualNodeRequest do
    alias __MODULE__
  @enforce_keys [:worker, :worker_name]
  defstruct(
    worker: nil,
    worker_name: nil
  )

  @spec new(%Dynamo{}, atom()) ::
          %AddVirtualNodeRequest{
            worker: %Dynamo{},
            worker_name: atom()
          }
  def new(worker, worker_name) do
    %AddVirtualNodeRequest{ worker: worker, worker_name: worker_name}
  end
end

defmodule Dynamo.AddWorkerRequest do

  alias __MODULE__
  @enforce_keys [:worker, :worker_name]
  defstruct(
    worker: nil,
    worker_name: nil
  )

  @spec new(%Dynamo{}, atom()) ::
          %AddWorkerRequest{
            worker: %Dynamo{},
            worker_name: atom()
          }
  def new(worker, worker_name) do
    %AddWorkerRequest{worker: worker, worker_name: worker_name}
  end
end

defmodule Dynamo.PutRequestFromClient do

  alias __MODULE__
  @enforce_keys [:key, :value]
  defstruct(
    key: nil,
    value: nil
  )

  @spec new(atom(), atom()) ::
          %PutRequestFromClient{
            key: atom(),
            value: atom()
          }
  def new(key, value) do
    %PutRequestFromClient{key: key, value: value}
  end
end

defmodule Dynamo.PutRequestToCoordinateNode do

  alias __MODULE__
  @enforce_keys [:client, :key, :value]
  defstruct(
    client: nil,
    key: nil,
    value: nil
  )

  @spec new(atom(), atom(), atom()) ::
          %PutRequestToCoordinateNode{
            client: atom(),
            key: atom(),
            value: atom()
          }
  def new(client, key, value) do
    %PutRequestToCoordinateNode{client: client, key: key, value: value}
  end
end

defmodule Dynamo.PutRequestToReplicaNode do

  alias __MODULE__
  @enforce_keys [:client, :key, :value]
  defstruct(
    client: nil,
    key: nil,
    value: nil
  )

  @spec new(atom(), atom(), atom()) ::
          %PutRequestToReplicaNode{
            client: atom(),
            key: atom(),
            value: atom()
          }
  def new(client, key, value) do
    %PutRequestToReplicaNode{client: client, key: key, value: value}
  end
end

defmodule Dynamo.PutResponseToCoordinator do

  alias __MODULE__
  @enforce_keys [:client, :key, :value]
  defstruct(
    client: nil,
    key: nil,
    value: nil
  )

  @spec new(atom(), atom(), atom()) ::
          %PutResponseToCoordinator{
            client: atom(),
            key: atom(),
            value: atom()
          }
  def new(client, key, value) do
    %PutResponseToCoordinator{client: client, key: key, value: value}
  end
end

defmodule Dynamo.GetRequestFromClient do

  alias __MODULE__
  @enforce_keys [:key]
  defstruct(
    key: nil
  )

  @spec new(atom()) ::
          %GetRequestFromClient{
            key: atom()
          }
  def new(key) do
    %GetRequestFromClient{key: key}
  end
end

defmodule Dynamo.GetRequestToWorkers do

  alias __MODULE__
  @enforce_keys [:key]
  defstruct(
    client: nil,
    key: nil
  )

  @spec new(atom(), atom()) ::
          %GetRequestToWorkers{
            client: atom(),
            key: atom(),
          }
  def new(client, key) do
    %GetRequestToWorkers{client: client, key: key}
  end
end

defmodule Dynamo.GetResponseFromWorkers do

  alias __MODULE__
  @enforce_keys [:key, :value]
  defstruct(
    client: nil,
    key: nil,
    value: nil
  )

  @spec new(atom(), atom(), atom()) ::
          %GetResponseFromWorkers{
            client: atom(),
            key: atom(),
            value: atom()
          }
  def new(client, key, value) do
    %GetResponseFromWorkers{client: client, key: key, value: value}
  end
end

defmodule Dynamo.GetResponseToClient do

  alias __MODULE__
  @enforce_keys [:key, :value]
  defstruct(
    key: nil,
    value: nil
  )

  @spec new(atom(), atom()) ::
          %GetResponseToClient{
            key: atom(),
            value: atom()
          }
  def new(key, value) do
    %GetResponseToClient{key: key, value: value}
  end
end




