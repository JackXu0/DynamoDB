defmodule Lab3Test do
  use ExUnit.Case
  doctest Dynamo
  import Emulation, only: [spawn: 2, send: 2]

  import Kernel,
    except: [spawn: 3, spawn: 1, spawn_link: 1, spawn_link: 3, send: 2]

  test "Nothing crashes during startup and heartbeats" do
    Emulation.init()
    
    # p, n ,r, w
    config =
      Dynamo.new_configuration(:a, 3, 8, 1, 1, 100)

    nodes = %{1 => "a", 2 => "b", 3 => "c", 4 => "d", 5 => "e", 6 => "f", 7 => "g", 8 => "h", 9 => "i", 10 => "j",
    11 => "1a", 12 => "1b", 13 => "1c", 14 => "1d", 15 => "1e", 16 => "1f", 17 => "1g", 18 => "1h", 19 => "1i", 20 => "1j"
  }
    IO.inspect(nodes)

    a = spawn(:a, fn -> Dynamo.become_worker(config, "a") end)
    for {x, y} <- nodes do  
      if x > 1 do
        IO.puts(y)
        atom = String.to_atom(y)

        send(String.to_atom(nodes[x-1]), :getConfig)
        config =
        receive do
          # {_, %Dynamo{}} -> %Dynamo{}
          msg -> msg
        after
          5_000 -> assert false
        end

        spawn(atom, fn -> Dynamo.become_worker(config, y) end)
        
        # :timer.sleep(1000)
        
        
      end
    end

    # a = spawn(:a, fn -> Dynamo.become_worker(base_config, "a") end)

    # :timer.sleep(1000)

    # send(:a, :getConfig)
    # config =
    # receive do
    #   # {_, %Dynamo{}} -> %Dynamo{}
    #   msg -> msg
    # after
    #   5_000 -> assert false
    # end

    # #IO.puts("1111 #{inspect(config)}")
    # :timer.sleep(1000)
    # b = spawn(:b, fn -> Dynamo.become_worker(config, "b") end)
    # :timer.sleep(1000)
    # IO.puts("b added to config")
    # send(:b, :getConfig)
    #     config =
    #     receive do
    #       # {_, %Dynamo{}} -> %Dynamo{}
    #       msg -> msg
    #     after
    #       30_000 -> assert false
    #     end
    # #IO.puts("1111 #{inspect(config)}")
    # :timer.sleep(1000)
    # c = spawn(:c, fn -> Dynamo.become_worker(config, "c") end)

    # :timer.sleep(1000)
    # IO.puts("c added to config")
    # send(:c, :getConfig)
    #     config =
    #     receive do
    #           {_, %Dynamo{}} -> %Dynamo{}
    #           msg -> msg
    #         after
    #           30_000 -> assert false
    #         end

    # :timer.sleep(1000)
    # d = spawn(:d, fn -> Dynamo.become_worker(config, "d") end)



    :timer.sleep(2000)

    # Emulation.append_fuzzers([Fuzzers.delay(30)])

    send(:a, %Dynamo.PutRequestFromClient{key: "key1", value: 111})
    

    handle = Process.monitor(a)

    receive do
      {:DOWN, ^handle, _, _, _} -> true

      msg -> 
        IO.puts("Put response before get #{inspect(msg)}")
        send(:f, %Dynamo.GetRequestFromClient{key: "key1"})
        IO.puts("after sending get")
    after
      30_000 -> assert false
    end

    receive do
      {:DOWN, ^handle, _, _, _} -> true

      msg -> 
        IO.puts("GET response #{inspect(msg)}")
    after
      30_000 -> assert false
    end


  after
    Emulation.terminate()
  end

  # test "RSM operations work" do
  #   Emulation.init()
  #   Emulation.append_fuzzers([Fuzzers.delay(2)])

  #   base_config =
  #     Raft.new_configuration([:a, :b, :c], :a, 100_000, 100_001, 1000)

  #   spawn(:b, fn -> Raft.become_follower(Raft.make_follower(base_config)) end)
  #   spawn(:c, fn -> Raft.become_follower(Raft.make_follower(base_config)) end)
  #   spawn(:a, fn -> Raft.become_leader(base_config) end)

  #   client =
  #     spawn(:client, fn ->
  #       client = Raft.Client.new_client(:c)
  #       {:ok, client} = Raft.Client.enq(client, 5)
  #       {{:value, v}, client} = Raft.Client.deq(client)
  #       IO.puts("get value #{v}")
  #       assert v == 5
  #       {v, _} = Raft.Client.deq(client)
  #       IO.puts("get value #{v}")
  #       assert v == :empty
  #     end)

  #   handle = Process.monitor(client)
  #   # Timeout.
  #   receive do
  #     {:DOWN, ^handle, _, _, _} -> true
  #   after
  #     30_000 -> assert false
  #   end
  # after
  #   Emulation.terminate()
  # end

  # test "RSM Logs are correctly updated" do
  #   Emulation.init()
  #   Emulation.append_fuzzers([Fuzzers.delay(2)])

  #   base_config =
  #     Raft.new_configuration([:a, :b, :c], :a, 100_000, 100_001, 1000)

  #   spawn(:b, fn -> Raft.become_follower(Raft.make_follower(base_config)) end)
  #   spawn(:c, fn -> Raft.become_follower(Raft.make_follower(base_config)) end)
  #   spawn(:a, fn -> Raft.become_leader(base_config) end)

  #   client =
  #     spawn(:client, fn ->
  #       view = [:a, :b, :c]
  #       client = Raft.Client.new_client(:c)
  #       # Perform one operation
  #       {:ok, _} = Raft.Client.enq(client, 5)
  #       # Now collect logs
  #       view |> Enum.map(fn x -> send(x, :send_log) end)

  #       logs =
  #         view
  #         |> Enum.map(fn x ->
  #           receive do
  #             {^x, log} -> log
  #           end
  #         end)

  #       log_lengths = logs |> Enum.map(&length/1)

  #       assert Enum.count(log_lengths, fn l -> l == 1 end) >= 2 &&
  #                !Enum.any?(log_lengths, fn l -> l > 1 end)
  #     end)

  #   handle = Process.monitor(client)
  #   # Timeout.
  #   receive do
  #     {:DOWN, ^handle, _, _, _} -> true
  #   after
  #     30_000 -> false
  #   end
  # after
  #   Emulation.terminate()
  # end

  # test "RSM replicas commit correctly" do
  #   Emulation.init()
  #   Emulation.append_fuzzers([Fuzzers.delay(2)])

  #   base_config =
  #     Raft.new_configuration([:a, :b, :c], :a, 100_000, 100_001, 1000)

  #   spawn(:b, fn -> Raft.become_follower(Raft.make_follower(base_config)) end)
  #   spawn(:c, fn -> Raft.become_follower(Raft.make_follower(base_config)) end)
  #   spawn(:a, fn -> Raft.become_leader(base_config) end)

  #   client =
  #     spawn(:client, fn ->
  #       view = [:a, :b, :c]
  #       client = Raft.Client.new_client(:c)
  #       # Perform one operation
  #       {:ok, client} = Raft.Client.enq(client, 5)
  #       # Now use a nop to force a commit.
  #       {:ok, _} = Raft.Client.nop(client)
  #       # Now collect queues
  #       view |> Enum.map(fn x -> send(x, :send_state) end)

  #       queues =
  #         view
  #         |> Enum.map(fn x ->
  #           receive do
  #             {^x, s} -> s
  #           end
  #         end)

  #       IO.puts("queues #{inspect(queues)}")


  #       q_lengths = queues |> Enum.map(&:queue.len/1)

  #       IO.puts("q lengths #{inspect(q_lengths)}")

  #       assert Enum.count(q_lengths, fn l -> l == 1 end) >= 2 &&
  #                !Enum.any?(q_lengths, fn l -> l > 1 end)

  #       q_values =
  #         queues
  #         |> Enum.map(&:queue.out/1)
  #         |> Enum.map(fn {v, _} -> v end)

  #       assert Enum.all?(q_values, fn l -> l == {:value, 5} || l == :empty end)
  #     end)

  #   handle = Process.monitor(client)
  #   # Timeout.
  #   receive do
  #     {:DOWN, ^handle, _, _, _} ->  true
  #   after
  #     30_000 -> false
  #   end
  # after
  #   Emulation.terminate()
  # end
end
