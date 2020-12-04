defmodule Raft do
  @moduledoc """
  An implementation of the Raft consensus protocol.
  """
  # Shouldn't need to spawn anything from this module, but if you do
  # you should add spawn to the imports.
  import Emulation, only: [send: 2, timer: 1, now: 0, whoami: 0]

  import Kernel,
    except: [spawn: 3, spawn: 1, spawn_link: 1, spawn_link: 3, send: 2]

  require Fuzzers
  # This allows you to use Elixir's loggers
  # for messages. See
  # https://timber.io/blog/the-ultimate-guide-to-logging-in-elixir/
  # if you are interested in this. Note we currently purge all logs
  # below Info
  require Logger

  # This structure contains all the process state
  # required by the Raft protocol.
  defstruct(
    # The list of current proceses.
    view: nil,
    # Current leader.
    current_leader: nil,
    # Time before starting an election.
    min_election_timeout: nil,
    max_election_timeout: nil,
    election_timer: nil,
    # Time between heartbeats from the leader.
    heartbeat_timeout: nil,
    heartbeat_timer: nil,
    # Persistent state on all servers.
    current_term: nil,
    voted_for: nil,
    # A short note on log structure: The functions that follow
    # (e.g., get_last_log_index, commit_log_index, etc.) all
    # assume that the log is a list with later entries (i.e.,
    # entries with higher index numbers) appearing closer to
    # the head of the list, and that index numbers start with 1.
    # For example if the log contains 3 entries committe in term
    # 2, 2, and 1 we would expect:
    #
    # `[{index: 3, term: 2, ..}, {index: 2, term: 2, ..},
    #     {index: 1, term: 1}]`
    #
    # If you change this structure, you will need to change
    # those functions.
    #
    # Finally, it might help to know that two lists can be
    # concatenated using `l1 ++ l2`
    log: nil,
    # Volatile state on all servers
    commit_index: nil,
    last_applied: nil,
    # Volatile state on leader
    is_leader: nil,
    next_index: nil,
    match_index: nil,
    # The queue we are building using this RSM.
    queue: nil
  )

  @doc """
  Create state for an initial Raft cluster. Each
  process should get an appropriately updated version
  of this state.
  """
  @spec new_configuration(
          [atom()],
          atom(),
          non_neg_integer(),
          non_neg_integer(),
          non_neg_integer()
        ) :: %Raft{}
  def new_configuration(
        view,
        leader,
        min_election_timeout,
        max_election_timeout,
        heartbeat_timeout
      ) do
    %Raft{
      view: view,
      current_leader: leader,
      min_election_timeout: min_election_timeout,
      max_election_timeout: max_election_timeout,
      heartbeat_timeout: heartbeat_timeout,
      # Start from term 1
      current_term: 1,
      voted_for: nil,
      log: [],
      commit_index: 0,
      last_applied: 0,
      is_leader: false,
      next_index: nil,
      match_index: nil,
      queue: :queue.new(),
    }
  end

  # Enqueue an item, this **modifies** the state
  # machine, and should only be called when a log
  # entry is committed.
  @spec enqueue(%Raft{}, any()) :: %Raft{}
  defp enqueue(state, item) do
    %{state | queue: :queue.in(item, state.queue)}
  end

  # Dequeue an item, modifying the state machine.
  # This function should only be called once a
  # log entry has been committed.
  @spec dequeue(%Raft{}) :: {:empty | {:value, any()}, %Raft{}}
  defp dequeue(state) do
    {ret, queue} = :queue.out(state.queue)
    {ret, %{state | queue: queue}}
  end

  @doc """
  Commit a log entry, advancing the state machine. This
  function returns a tuple:
  * The first element is {requester, return value}. Your
    implementation should ensure that the leader who committed
    the log entry sends the return value to the requester.
  * The second element is the updated state.
  """
  @spec commit_log_entry(%Raft{}, %Raft.LogEntry{}) ::
          {{atom() | pid(), :ok | :empty | {:value, any()}}, %Raft{}}
  def commit_log_entry(state, entry) do
    case entry do
      %Raft.LogEntry{operation: :nop, requester: r, index: i} ->
        {{r, :ok}, %{state | commit_index: i}}

      %Raft.LogEntry{operation: :enq, requester: r, argument: e, index: i} ->
        {{r, :ok}, %{enqueue(state, e) | commit_index: i}}

      %Raft.LogEntry{operation: :deq, requester: r, index: i} ->
        {ret, state} = dequeue(state)
        {{r, ret}, %{state | commit_index: i}}

      %Raft.LogEntry{} ->
        raise "Log entry with an unknown operation: maybe an empty entry?"

      _ ->
        raise "Attempted to commit something that is not a log entry."
    end
  end

  @doc """
  Commit log at index `index`. This index, which one should read from
  the log entry is assumed to start at 1. This function **does not**
  ensure that commits are processed in order.
  """
  @spec commit_log_index(%Raft{}, non_neg_integer()) ::
          {:noentry | {atom(), :ok | :empty | {:value, any()}}, %Raft{}}
  def commit_log_index(state, index) do
    if length(state.log) < index do
      {:noentry, state}
    else
      # Note that entry indexes are all 1, which in
      # turn means that we expect commit indexes to
      # be 1 indexed. Now a list is a reversed log,
      # so what we can do here is simple: 
      # Given 0-indexed index i, length(log) - 1 - i
      # is the ith list element. => length(log) - (i +1),
      # and hence length(log) - index is what we want.
      correct_idx = length(state.log) - index
      commit_log_entry(state, Enum.at(state.log, correct_idx))
    end
  end

  # The next few functions are public so we can test them, see
  # log_test.exs.
  @doc """
  Get index for the last log entry.
  """
  @spec get_last_log_index(%Raft{}) :: non_neg_integer()
  def get_last_log_index(state) do
    Enum.at(state.log, 0, Raft.LogEntry.empty()).index
  end

  @doc """
  Get term for the last log entry.
  """
  @spec get_last_log_term(%Raft{}) :: non_neg_integer()
  def get_last_log_term(state) do
    Enum.at(state.log, 0, Raft.LogEntry.empty()).term
  end

  @doc """
  Check if log entry at index exists.
  """
  @spec logged?(%Raft{}, non_neg_integer()) :: boolean()
  def logged?(state, index) do
    index > 0 && length(state.log) >= index
  end

  @doc """
  Get log entry at `index`.
  """
  @spec get_log_entry(%Raft{}, non_neg_integer()) ::
          :no_entry | %Raft.LogEntry{}
  def get_log_entry(state, index) do
    if index <= 0 || length(state.log) < index do
      :noentry
    else
      # Note that entry indexes are all 1, which in
      # turn means that we expect commit indexes to
      # be 1 indexed. Now a list is a reversed log,
      # so what we can do here is simple:
      # Given 0-indexed index i, length(log) - 1 - i
      # is the ith list element. => length(log) - (i +1),
      # and hence length(log) - index is what we want.
      correct_idx = length(state.log) - index
      Enum.at(state.log, correct_idx)
    end
  end

  @doc """
  Get log entries starting at index.
  """
  @spec get_log_suffix(%Raft{}, non_neg_integer()) :: [%Raft.LogEntry{}]
  def get_log_suffix(state, index) do
    if length(state.log) < index do
      []
    else
      correct_idx = length(state.log) - index
      Enum.take(state.log, correct_idx + 1)
    end
  end

  @doc """
  Truncate log entry at `index`. This removes log entry
  with index `index` and larger.
  """
  @spec truncate_log_at_index(%Raft{}, non_neg_integer()) :: %Raft{}
  def truncate_log_at_index(state, index) do
    if length(state.log) < index do
      # Nothing to do
      state
    else
      to_drop = length(state.log) - index + 1
      %{state | log: Enum.drop(state.log, to_drop)}
    end
  end

  @doc """
  Add log entries to the log. This adds entries to the beginning
  of the log, we assume that entries are already correctly ordered
  (see structural note about log above.).
  """
  @spec add_log_entries(%Raft{}, [%Raft.LogEntry{}]) :: %Raft{}
  def add_log_entries(state, entries) do
    %{state | log: entries ++ state.log}
  end

  @doc """
  make_leader changes process state for a process that
  has just been elected leader.
  """
  @spec make_leader(%Raft{}) :: %Raft{
          is_leader: true,
          next_index: map(),
          match_index: map()
        }
  def make_leader(state) do
    log_index = get_last_log_index(state)

    # next_index needs to be reinitialized after each
    # election.
    next_index =
      state.view
      |> Enum.map(fn v -> {v, log_index + 1} end)
      |> Map.new()

    # match_index needs to be reinitialized after each
    # election.
    match_index =
      state.view
      |> Enum.map(fn v -> {v, 0} end)
      |> Map.new()

    

    %{
      state
      | is_leader: true,
        next_index: next_index,
        match_index: match_index,
        current_leader: whoami()
    }

    
  end

  @doc """
  make_follower changes process state for a process
  to mark it as a follower.
  """
  @spec make_follower(%Raft{}) :: %Raft{
          is_leader: false
        }
  def make_follower(state) do
    %{state | is_leader: false}
  end

  # update_leader: update the process state with the
  # current leader.
  @spec update_leader(%Raft{}, atom()) :: %Raft{current_leader: atom()}
  defp update_leader(state, who) do
    %{state | current_leader: who}
  end

  # Compute a random election timeout between
  # state.min_election_timeout and state.max_election_timeout.
  # See the paper to understand the reasoning behind having
  # a randomized election timeout.
  @spec get_election_time(%Raft{}) :: non_neg_integer()
  defp get_election_time(state) do
    state.min_election_timeout +
      :rand.uniform(
        state.max_election_timeout -
          state.min_election_timeout
      )
  end

  # Save a handle to the election timer.
  @spec save_election_timer(%Raft{}, reference()) :: %Raft{}
  defp save_election_timer(state, timer) do
    %{state | election_timer: timer}
  end

  # Save a handle to the hearbeat timer.
  @spec save_heartbeat_timer(%Raft{}, reference()) :: %Raft{}
  defp save_heartbeat_timer(state, timer) do
    %{state | heartbeat_timer: timer}
  end

  # Utility function to send a message to all
  # processes other than the caller. Should only be used by leader.
  @spec broadcast_to_others(%Raft{is_leader: true}, any()) :: [boolean()]
  defp broadcast_to_others(state, message) do
    me = whoami()

    state.view
    |> Enum.filter(fn pid -> pid != me end)
    |> Enum.map(fn pid -> send(pid, message) end)
  end

  # END OF UTILITY FUNCTIONS. You should not need to (but are allowed to)
  # change any of the code above this line, but will definitely need to
  # change the code that follows.

  # This function should cancel the current
  # election timer, and set  a new one. You can use
  # `get_election_time` defined above to get a
  # randomized election timeout. You might need
  # to call this function from within your code.
  @spec reset_election_timer(%Raft{}) :: %Raft{}
  defp reset_election_timer(state) do
    # TODO: Set a new election timer
    # You might find `save_election_timer` of use.
    if state.election_timer do
      Emulation.cancel_timer(state.election_timer)
    end
    timer = timer(get_election_time(state))
    save_election_timer(state, timer)
  end

  # This function should cancel the current
  # hearbeat timer, and set  a new one. You can
  # get heartbeat timeout from `state.heartbeat_timeout`.
  # You might need to call this from your code.
  @spec reset_heartbeat_timer(%Raft{}) :: %Raft{}
  defp reset_heartbeat_timer(state) do
    # TODO: Set a new heartbeat timer.
    # You might find `save_heartbeat_timer` of use.
    if state.heartbeat_timer do
      Emulation.cancel_timer(state.heartbeat_timer)
    end
    timer = timer(state.heartbeat_timeout)
    save_heartbeat_timer(state, timer)
  end

  def apply_all_follower(state, left, right) do
    if left > right do
      state
    else
      
      {_, state} = commit_log_index(state, left)
      apply_all_follower(state,left+1, right)
    end
  end

  def apply_all_leader(state, left, right) do
    if left > right do
      state
    else
      {{r, v}, state} = commit_log_index(state, left)
      IO.puts("leader sending msg #{inspect(v)} to #{inspect(r)}")
      send(r, v)
      # send heartbeat to notify others new log applied
      broadcast_to_others(state, {:apply, left})
      apply_all_leader(state,left+1, right)
    end
  end

  def check_latest_commit_value(state, left, right, running) do
    if !running do
      left
    else
      if Enum.count(Enum.filter(Map.values(state.match_index), fn x -> x > left end)) > length(Map.values(state.next_index))/2 do
        check_latest_commit_value(state, left + 1, right, true)
      else
        check_latest_commit_value(state, left, right, false)
      end
    end
  end

  def boardcast_entries(state) do
    Enum.each(state.next_index, fn {server, next_log_index} ->
      if server != whoami() do
        if next_log_index > 1 do
          send(server, %Raft.AppendEntryRequest{
            term: state.current_term,
            leader_id: whoami(),
            prev_log_index: next_log_index -  1,
            prev_log_term: Map.get(get_log_entry(state, next_log_index -  1), :term),
            entries: get_log_suffix(state, next_log_index),
            leader_commit_index: state.commit_index
          })
        else
          send(server, %Raft.AppendEntryRequest{
            term: state.current_term,
            leader_id: whoami(),
            prev_log_index: 0,
            prev_log_term: 0,
            entries: get_log_suffix(state, next_log_index),
            leader_commit_index: state.commit_index
          })
        end
      end
    end)
  end

  @doc """
  This function transitions a process so it is
  a follower.
  """
  @spec become_follower(%Raft{}) :: no_return()
  def become_follower(state) do
    # TODO: Do anything you need to when a process
    # transitions to a follower.

    IO.puts(" #{inspect(whoami())} became follower")

    # reset an election timer
    state = reset_election_timer(state)

    # reset vote for
    state = %{state | voted_for: nil}

    follower(make_follower(state), nil)
  end

  @doc """
  This function implements the state machine for a process
  that is currently a follower.

  `extra_state` can be used to hod anything that you find convenient
  when building your implementation.
  """
  @spec follower(%Raft{is_leader: false}, any()) :: no_return()
  def follower(state, extra_state) do
    receive do
      # Messages that are a part of Raft.
      {sender,
       %Raft.AppendEntryRequest{
         term: term,
         leader_id: leader_id,
         prev_log_index: prev_log_index,
         prev_log_term: prev_log_term,
         entries: entries,
         leader_commit_index: leader_commit_index
       }} ->
        # TODO: Handle an AppendEntryRequest received by a
        # follower
        IO.puts("Follower #{inspect(whoami())} append entry request #{inspect(%Raft.AppendEntryRequest{
            term: term,
            leader_id: leader_id,
            prev_log_index: prev_log_index,
            prev_log_term: prev_log_term,
            entries: entries,
            leader_commit_index: leader_commit_index
          })}")

        
        
        cond do

          # reply flase if term < current term
          term < state.current_term -> 
            send(sender, %Raft.AppendEntryResponse{term: state.current_term, log_index: 0, success: false})
            IO.puts("Follower #{inspect(whoami())} return false as append reply because term issues")
            follower(state, extra_state)

          # reply false if there are previous logs, but found a conflict
          prev_log_term > 0 and (!logged?(state, prev_log_index) || Map.get(get_log_entry(state, prev_log_index), :term) != prev_log_term) ->
            state = update_leader(state, leader_id)
            state = %{state | current_term: term}
            send(sender, %Raft.AppendEntryResponse{term: state.current_term, log_index: 0, success: false})
            IO.puts("Follower #{inspect(whoami())} return false as append reply because prec issues")
            # reset election timer
            state = reset_election_timer(state)
            follower(state, extra_state)

          # If there are no previous logs
          prev_log_term == 0 ->
            state = update_leader(state, leader_id)
            state = %{state | current_term: term}
            state = add_log_entries(state, entries)
            send(sender, %Raft.AppendEntryResponse{term: state.current_term, log_index: get_last_log_index(state), success: true})
            IO.puts("Follower #{inspect(whoami())} return true as append reply. first log")
            # reset election timer
            state = reset_election_timer(state)
            follower(state, extra_state)
          
          true ->
            # update current leader id
            state = update_leader(state, leader_id)
            state = %{state | current_term: term}
            # check each new entry, if it conflicts with an existing entry. If there is a conflict:
            # 1. truncate it and all logs afterwards stored on this state machine
            # 2. keep logs in the entries until this entry

            # Get the smallest index from entries
            min_index = if length(entries) >= 1 do
                          Map.get(List.last(entries), :index)
                        else
                          get_last_log_index(state)
                        end

            # Do truncate
            state = truncate_log_at_index(state, min_index)
            IO.puts("Follower #{inspect(whoami())} Log after truncate #{inspect(state.log)}")
            # append any new entries not already in the log
            state = add_log_entries(state, entries)
            IO.puts("Follower #{inspect(whoami())} Log after append #{inspect(state.log)}")

            # Update commit index if leaderCommit > commitIndex, set commitIndex = min(leaderCommit, index of last new entry)
            state = if leader_commit_index > state.commit_index do
                      IO.puts("Follower #{inspect(whoami())} updates commit index to: #{state.commit_index}")
                      %{state | commit_index: min(leader_commit_index, get_last_log_index(state))}
                    else
                      state
                    end
              
            send(sender, %Raft.AppendEntryResponse{term: state.current_term, log_index: get_last_log_index(state) , success: true})
            # reset election timer
            state = reset_election_timer(state)
            follower(state, extra_state)
            
        end
        

      {sender,
       %Raft.AppendEntryResponse{
         term: term,
         log_index: index,
         success: succ
       }} ->
        # TODO: Handle an AppendEntryResponse received by
        # a follower.
        IO.puts(
          "Follower #{inspect(whoami())} received append entry response #{term}," <>
            " index #{index}, succcess #{inspect(succ)}"
        )

        follower(state, extra_state)

        # raise "Not yet implemented"

      {sender,
       %Raft.RequestVote{
         term: term,
         candidate_id: candidate,
         last_log_index: last_log_index,
         last_log_term: last_log_term
       }} ->
        # TODO: Handle a RequestVote call received by a
        # follower.
        IO.puts("Follower #{inspect(whoami())} receives request vote #{inspect(%Raft.RequestVote{
          term: term,
          candidate_id: candidate,
          last_log_index: last_log_index,
          last_log_term: last_log_term
        })}")

        # reset election timer
        # state = reset_election_timer(state)


        # reply false if term < current term
        cond do
        # TODO: Handle a RequestVoteResponse.
             # if term < state.current_term do
            term < state.current_term -> 
              send(sender, %Raft.RequestVoteResponse{term: state.current_term, granted: false})

            (state.voted_for == nil or state.voted_for == candidate) and ((last_log_index >= get_last_log_index(state) and last_log_term == get_last_log_term(state)) or last_log_term > get_last_log_term(state)) ->
              # reset election timer
              state = reset_election_timer(state)
              send(sender, %Raft.RequestVoteResponse{term: state.current_term, granted: true})

            true ->
              # reset election timer
              state = reset_election_timer(state)
              send(sender, %Raft.RequestVoteResponse{term: state.current_term, granted: false})
        end

        follower(state, extra_state)
        

      {sender,
       %Raft.RequestVoteResponse{
         term: term,
         granted: granted
       }} ->
        # TODO: Handle a RequestVoteResponse.
        IO.puts(
          "Follower #{inspect(whoami())} received RequestVoteResponse " <>
            "term = #{term}, granted = #{inspect(granted)}"
        )

        follower(state, extra_state)
        # raise "Not yet implemented"

      :timer ->
        # if election timeout elapses without receiving AppendEntries RPC, or granting vote to candidates
        # convert to candidate
        become_candidate(state)

      {sender, {:apply, index}} ->
        state = apply_all_follower(state, state.last_applied + 1, index)
        IO.puts("Follower #{inspect(whoami())} applied entry #{index} queue: #{inspect(state.queue)}")
        state = %{state | last_applied: index}
        follower(state, extra_state)


      # Messages from external clients. In each case we
      # tell the client that it should go talk to the
      # leader.
      {sender, :nop} ->
        # IO.puts("nop responder triggered")
        # IO.puts("nop responder triggered. current leader is #{state.current_leader}")
        send(sender, {:redirect, state.current_leader})
        # IO.puts("sent response to the client")
        follower(state, extra_state)

      {sender, {:enq, item}} ->
        send(sender, {:redirect, state.current_leader})
        follower(state, extra_state)

      {sender, :deq} ->
        send(sender, {:redirect, state.current_leader})
        follower(state, extra_state)

      # Messages for debugging [Do not modify existing ones,
      # but feel free to add new ones.]
      {sender, :send_state} ->
        send(sender, state.queue)
        IO.puts("Follower #{inspect(whoami())} responded with queue #{inspect(state.queue)}")
        follower(state, extra_state)

      {sender, :send_log} ->
        send(sender, state.log)
        follower(state, extra_state)

      {sender, :whois_leader} ->
        send(sender, {state.current_leader, state.current_term})
        follower(state, extra_state)

      {sender, :current_process_type} ->
        send(sender, :follower)
        follower(state, extra_state)

      {sender, {:set_election_timeout, min, max}} ->
        state = %{state | min_election_timeout: min, max_election_timeout: max}
        state = reset_election_timer(state)
        send(sender, :ok)
        follower(state, extra_state)

      {sender, {:set_heartbeat_timeout, timeout}} ->
        send(sender, :ok)
        follower(%{state | heartbeat_timeout: timeout}, extra_state)
    end
  end

  @doc """
  This function transitions a process that is not currently
  the leader so it is a leader.
  """
  @spec become_leader(%Raft{is_leader: false}) :: no_return()
  def become_leader(state) do
    # TODO: Send out any one time messages that need to be sent,
    # you might need to update the call to leader too.

    IO.puts(" #{inspect(whoami())} became leader")
    # reset heartbeat timer
    state = reset_heartbeat_timer(state)
    
    # reset vote for
    state = %{state | voted_for: nil}

    # send intial empty AppendEntries RPCs to each server
    broadcast_to_others(state, %Raft.AppendEntryRequest{
         term: state.current_term,
         leader_id: whoami(),
         prev_log_index: get_last_log_index(state),
         prev_log_term: get_last_log_term(state),
         entries: [],
         leader_commit_index: state.commit_index
       })

    leader(make_leader(state), 1)
  end

  @doc """
  This function implements the state machine for a process
  that is currently the leader.
 
  `extra_state` can be used to hold any additional information.
  HINT: It might be useful to track the number of responses
  received for each AppendEntry request.
  """
  @spec leader(%Raft{is_leader: true}, any()) :: no_return()
  def leader(state, extra_state) do
    receive do
      # Messages that are a part of Raft.
      {sender,
       %Raft.AppendEntryRequest{
         term: term,
         leader_id: leader_id,
         prev_log_index: prev_log_index,
         prev_log_term: prev_log_term,
         entries: entries,
         leader_commit_index: leader_commit_index
       }} ->
        # TODO: Handle an AppendEntryRequest seen by the leader.
        IO.puts("Leader receive Append entry request from #{inspect(sender)} #{inspect(%Raft.AppendEntryRequest{
          term: term,
          leader_id: leader_id,
          prev_log_index: prev_log_index,
          prev_log_term: prev_log_term,
          entries: entries,
          leader_commit_index: leader_commit_index
        })}")

        # if term > current term, convert to follower
        if term > state.current_term do
          state = %{state | current_term: term}
          state = %{state | current_leader: leader_id}
          if state.heartbeat_timer do
            Emulation.cancel_timer(state.heartbeat_timer)
          end
          become_follower(state)
          IO.puts("Leader become follower")
        else
          leader(state, extra_state)
        end

       


      {sender,
       %Raft.AppendEntryResponse{
         term: term,
         log_index: index,
         success: succ
       }} ->
        # TODO: Handle an AppendEntryResposne received by the leader.
        IO.puts("Leader receives append entry response from #{inspect(sender)} #{inspect(%Raft.AppendEntryResponse{
            term: term,
            log_index: index,
            success: succ
          })}")
        
        cond do
          # if failed, decrease next index, and retry append entry
          succ == false ->
            state =  %{state | next_index: %{state.next_index | sender => state.next_index[sender] - 1}}
            if state.next_index[sender] > 1 do
              IO.puts("Leader state before resending to #{inspect(sender)} #{inspect(state)}")
              send(sender, %Raft.AppendEntryRequest{
                term: state.current_term,
                leader_id: whoami(),
                prev_log_index: state.next_index[sender] -  1,
                prev_log_term: Map.get(get_log_entry(state, state.next_index[sender] -  1), :term),
                entries: get_log_suffix(state, state.next_index[sender]),
                leader_commit_index: state.commit_index
              })
              IO.puts("Leader Resending requests to #{inspect(sender)}, prev log index #{state.next_index[sender] -  1}")
              leader(state, extra_state)   
            else
              send(sender, %Raft.AppendEntryRequest{
                term: state.current_term,
                leader_id: whoami(),
                prev_log_index: 0,
                prev_log_term: 0,
                entries: get_log_suffix(state, 1),
                leader_commit_index: state.commit_index
              })
              IO.puts("Leader Resending requests to #{inspect(sender)}, prev log index 0")
              leader(state, extra_state)   
            end

          # TODO: 
          # if success, update next index and match index
          succ == true ->
            # if new log appended for one state machine
            if index > state.match_index[sender] do
              state = %{state | next_index: %{state.next_index | sender => index + 1}}
              state = %{state | match_index: %{state.match_index | sender => index}}
              committed_to_this_index = check_latest_commit_value(state, state.commit_index, get_last_log_index(state), true)
              IO.puts("commited to this index: #{committed_to_this_index} commited index: #{state.commit_index}")
              state = apply_all_leader(state, state.commit_index + 1, committed_to_this_index)
              state = %{state | commit_index: committed_to_this_index}
              state = %{state | last_applied: committed_to_this_index}
              IO.puts("Updated next index #{inspect(state.next_index)}")
              IO.puts("updated match index #{inspect(state.match_index)}")
              leader(state, extra_state)
            else
              leader(state, extra_state)
            end          
        end

      {sender,
       %Raft.RequestVote{
         term: term,
         candidate_id: candidate,
         last_log_index: last_log_index,
         last_log_term: last_log_term
       }} ->
        # TODO: Handle a RequestVote call at the leader.
        IO.puts("Leader receives request vote #{inspect(%Raft.RequestVote{
            term: term,
            candidate_id: candidate,
            last_log_index: last_log_index,
            last_log_term: last_log_term
          })}")

        # if term > current term, convert to follower and vote
        if term > state.current_term do
          IO.puts("Leader become follower and vote")
          cond do
            # if can vote for the candidate and candidate's logs are new enough, grant vote
            (state.voted_for == nil or state.voted_for == candidate) and 
            ((last_log_index >= get_last_log_index(state) and last_log_term == get_last_log_term(state)) or last_log_term > get_last_log_term(state)) ->
                send(sender, %Raft.RequestVoteResponse{term: state.current_term, granted: true})

            # else, reject the vote
            true ->
              send(sender, %Raft.RequestVoteResponse{term: state.current_term, granted: false})
          end
          if state.heartbeat_timer do
            Emulation.cancel_timer(state.heartbeat_timer)
          end
          become_follower(state)
        else
          # reject the vote if current term > term of the candidate
          send(sender, %Raft.RequestVoteResponse{term: state.current_term, granted: false})
          leader(state, extra_state)
        end
        

      {sender,
       %Raft.RequestVoteResponse{
         term: term,
         granted: granted
       }} ->
        # TODO: Handle RequestVoteResponse at a leader.         
        IO.puts("Leader request vote response #{inspect(%Raft.RequestVoteResponse{
            term: term,
            granted: granted
          })}")

        # if term > current term, convert to follower
        # if term > state.current_term do
        #   state = %{state | current_term: term}
        #   become_follower(state)
        # else
        #   leader(state, extra_state)
        # end

        
        
      :timer ->
        # when heartbeat timer elapse, send empty append entry requests to maintain leadership
        boardcast_entries(state)

        state = reset_heartbeat_timer(state)

        leader(state, extra_state)

      # Messages from external clients. For all of what follows
      # you should send the `sender` an :ok (see `Raft.Client`
      # the log entry corresponding to the request has been **committed**.
      {sender, :nop} ->
        # TODO: entry is the log entry that you need to
        # append.
        entry =
          Raft.LogEntry.nop(
            get_last_log_index(state) + 1,
            state.current_term,
            sender
          )

        # add to log entries
        state = add_log_entries(state, [entry])

        # boardcast to all others
        IO.puts("Leader boardcast :nop")
        boardcast_entries(state)
        
        

        # TODO: You might need to update the following call.
        leader(state, extra_state)

      {sender, {:enq, item}} ->
        # TODO: entry is the log entry that you need to
        # append.
        entry =
          Raft.LogEntry.enqueue(
            get_last_log_index(state) + 1,
            state.current_term,
            sender,
            item
          )

        # add to log entries
        state = add_log_entries(state, [entry])

        # boardcast to all others
        IO.puts("Leader boardcast :enq")
        boardcast_entries(state)

        # TODO: You might need to update the following call.
        leader(state, extra_state)

      {sender, :deq} ->
        # TODO: entry is the log entry that you need to
        # append.
        entry =
          Raft.LogEntry.dequeue(
            get_last_log_index(state) + 1,
            state.current_term,
            sender
          )
        # update next index and match index for leader
        # state = %{state | next_index: %{state.next_index | whoami() => state.next_index[whoami()] + 1}}
        # state = %{state | match_index: %{state.match_index | whoami() => state.match_index[whoami()] + 1}}
        # add to log entries
        state = add_log_entries(state, [entry])

        # boardcast to all others
        IO.puts("Leader boardcast :deq")
        boardcast_entries(state)

        # TODO: You might need to update the following call.
        leader(state, extra_state)

      # Messages for debugging [Do not modify existing ones,
      # but feel free to add new ones.]
      {sender, :send_state} ->
        send(sender, state.queue)
        leader(state, extra_state)

      {sender, :send_log} ->
        send(sender, state.log)
        leader(state, extra_state)

      {sender, :whois_leader} ->
        send(sender, {whoami(), state.current_term})
        leader(state, extra_state)

      {sender, :current_process_type} ->
        send(sender, :leader)
        leader(state, extra_state)

      {sender, {:set_election_timeout, min, max}} ->
        send(sender, :ok)

        leader(
          %{state | min_election_timeout: min, max_election_timeout: max},
          extra_state
        )

      {sender, {:set_heartbeat_timeout, timeout}} ->
        state = %{state | heartbeat_timeout: timeout}
        state = reset_heartbeat_timer(state)
        send(sender, :ok)
        leader(state, extra_state)
    end
  end

  @doc """
  This function transitions a process to candidate.
  """
  @spec become_candidate(%Raft{is_leader: false}) :: no_return()
  def become_candidate(state) do
    # TODO:   Send out any messages that need to be sent out
    # you might need to update the call to candidate below.
    IO.puts(" #{inspect(whoami())} became candidate")
    # increment the current term
    state = %{state | current_term: state.current_term + 1}

    # reset election timer
    state = reset_election_timer(state)

    # send request vote request to all others
    broadcast_to_others(state, %Raft.RequestVote{
         term: state.current_term,
         candidate_id: whoami(),
         last_log_index: get_last_log_index(state),
         last_log_term: get_last_log_term(state)
       })

    # vote for itself
    state = %{state | voted_for: whoami()}

    candidate(state, 1)
  end

  @doc """
  This function implements the state machine for a process
  that is currently a candidate.

  `extra_state` can be used to store any additional information
  required, e.g., to count the number of votes received.
  """
  @spec candidate(%Raft{is_leader: false}, any()) :: no_return()
  def candidate(state, extra_state) do
    receive do
      {sender,
       %Raft.AppendEntryRequest{
         term: term,
         leader_id: leader_id,
         prev_log_index: prev_log_index,
         prev_log_term: prev_log_term,
         entries: entries,
         leader_commit_index: leader_commit_index
       }} ->
        # TODO: Handle an AppendEntryRequest as a candidate
        IO.puts("Candidate #{inspect(whoami())} receive Append entry request from #{inspect(sender)} #{inspect(%Raft.AppendEntryRequest{
          term: term,
          leader_id: leader_id,
          prev_log_index: prev_log_index,
          prev_log_term: prev_log_term,
          entries: entries,
          leader_commit_index: leader_commit_index
        })}")

        # if received an append entry request from the new leader, become follower
        if term >= state.current_term do
          state = %{state | current_term: term}
          state = %{state | current_leader: leader_id}
          become_follower(state)
        else
          candidate(state, extra_state)
        end

      {sender,
       %Raft.AppendEntryResponse{
         term: term,
         log_index: index,
         success: succ
       }} ->
        # TODO: Handle an append entry response as a candidate
        IO.puts("Candidate #{inspect(whoami())} receive Append entry response from #{inspect(sender)} #{inspect(%Raft.AppendEntryResponse{
          term: term,
          log_index: index,
          success: succ
        })}")

        candidate(state, extra_state)

        # if received an append entry request from the new leader, become follower
        # if term > state.current_term do
        #   state = %{state | current_term: term}
        #   become_follower(state)
        # else
        #   candidate(state, extra_state)
        # end

      {sender,
       %Raft.RequestVote{
         term: term,
         candidate_id: candidate,
         last_log_index: last_log_index,
         last_log_term: last_log_term
       }} ->
        # TODO: Handle a RequestVote response as a candidate.
        IO.puts("Candidate #{inspect(whoami())} receive request vote from #{inspect(sender)} #{inspect(%Raft.RequestVote{
          term: term,
          candidate_id: candidate,
          last_log_index: last_log_index,
          last_log_term: last_log_term
        })}")

        # if received an append entry request from the new leader, become follower
        if term > state.current_term do
          # state = %{state | current_term: term}
          become_follower(state)
        else
          # if term < state.current_term, return false
          send(sender, %Raft.RequestVoteResponse{term: state.current_term, granted: false})
          candidate(state, extra_state)
        end

        # TODO: return false 

      {sender,
       %Raft.RequestVoteResponse{
         term: term,
         granted: granted
       }} ->
        # TODO: Handle a RequestVoteResposne as a candidate.
        IO.puts(
          "Candidate #{inspect(whoami())} received RequestVoteResponse from #{inspect(sender)} " <>
            "term = #{term}, granted = #{inspect(granted)}, current vote count: #{extra_state}"
        )

        #TODO: if vote granted, check if get the majority of the votes
        # if it this, become the leader
        if granted do
          IO.puts("majority ======= #{(length(state.view))/2}")
          if extra_state > (length(state.view))/2 do
            if state.election_timer do
              Emulation.cancel_timer(state.election_timer)
            end
            become_leader(state)
          else
            candidate(state, extra_state + 1)
          end
        end

        

      :timer ->
        # if election timeout, start new election
        become_candidate(state)

      # Messages from external clients.
      {sender, :nop} ->
        # Redirect in hopes that the current process
        # eventually gets elected leader.
        send(sender, {:redirect, whoami()})
        candidate(state, extra_state)

      {sender, {:enq, item}} ->
        # Redirect in hopes that the current process
        # eventually gets elected leader.
        send(sender, {:redirect, whoami()})
        candidate(state, extra_state)

      {sender, :deq} ->
        # Redirect in hopes that the current process
        # eventually gets elected leader.
        send(sender, {:redirect, whoami()})
        candidate(state, extra_state)

      # Messages for debugging [Do not modify existing ones,
      # but feel free to add new ones.]
      {sender, :send_state} ->
        send(sender, state.queue)
        candidate(state, extra_state)

      {sender, :send_log} ->
        send(sender, state.log)
        candidate(state, extra_state)

      {sender, :whois_leader} ->
        send(sender, {:candidate, state.current_term})
        candidate(state, extra_state)

      {sender, :current_process_type} ->
        send(sender, :candidate)
        candidate(state, extra_state)

      {sender, {:set_election_timeout, min, max}} ->
        state = %{state | min_election_timeout: min, max_election_timeout: max}
        state = reset_election_timer(state)
        send(sender, :ok)
        candidate(state, extra_state)

      {sender, {:set_heartbeat_timeout, timeout}} ->
        send(sender, :ok)
        candidate(%{state | heartbeat_timeout: timeout}, extra_state)
    end
  end
end

defmodule Raft.Client do
  import Emulation, only: [send: 2]

  import Kernel,
    except: [spawn: 3, spawn: 1, spawn_link: 1, spawn_link: 3, send: 2]

  @moduledoc """
  A client that can be used to connect and send
  requests to the RSM.
  """
  alias __MODULE__
  @enforce_keys [:leader]
  defstruct(leader: nil)

  @doc """
  Construct a new Raft Client. This takes an ID of
  any process that is in the RSM. We rely on
  redirect messages to find the correct leader.
  """
  @spec new_client(atom()) :: %Client{leader: atom()}
  def new_client(member) do
    %Client{leader: member}
  end

  @doc """
  Send a nop request to the RSM.
  """
  @spec nop(%Client{}) :: {:ok, %Client{}}
  def nop(client) do
    leader = client.leader
    send(leader, :nop)

    receive do
      {_, {:redirect, new_leader}} ->
        nop(%{client | leader: new_leader})

      {_, :ok} ->
        {:ok, client}
    end
  end

  @doc """
  Send a dequeue request to the RSM.
  """
  @spec deq(%Client{}) :: {:empty | {:value, any()}, %Client{}}
  def deq(client) do
    leader = client.leader
    send(leader, :deq)

    receive do
      {_, {:redirect, new_leader}} ->
        deq(%{client | leader: new_leader})

      {_, v} ->
        {v, client}
    end
  end

  @doc """
  Send an enqueue request to the RSM.
  """
  @spec enq(%Client{}, any()) :: {:ok, %Client{}}
  def enq(client, item) do
    leader = client.leader
    send(leader, {:enq, item})

    receive do
      {_, :ok} ->
        {:ok, client}

      {_, {:redirect, new_leader}} ->
        enq(%{client | leader: new_leader}, item)
    end
  end
end

