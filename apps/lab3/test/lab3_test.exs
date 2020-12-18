defmodule Lab3Test do
  use ExUnit.Case
  doctest Dynamo
  import Emulation, only: [spawn: 2, send: 2]

  import Kernel,
    except: [spawn: 3, spawn: 1, spawn_link: 1, spawn_link: 3, send: 2]


  test "Nothing crashes during startup and heartbeats" do
      Emulation.init()
      # 0, 0.1, 0.3, 0.5, 0.7, 1, 1.5, 2 
      Emulation.append_fuzzers([Fuzzers.delay(4.0)])
      # Emulation.mark_unfuzzable()
      configs = [
        Dynamo.new_configuration(:a, 3, 5, 1, 1, 0),
        Dynamo.new_configuration(:a, 3, 5, 2, 2, 0),
        Dynamo.new_configuration(:a, 3, 5, 3, 3, 0),

      ]
      # p, n ,r, w
      config =
        Dynamo.new_configuration(:a, 3, 5, 1, 1, 0)

      nodes = %{1 => "a", 2 => "b", 3 => "c", 4 => "d", 5 => "e", 6 => "f", 7 => "g", 8 => "h", 9 => "i", 10 => "j",
        11 => "k", 12 => "l", 13 => "m", 14 => "n", 15 => "o", 16 => "p", 17 => "q", 18 => "r", 19 => "s", 20 => "t"
      }
      # IO.inspect(nodes)
      ans = 
      0..899
      |> Enum.map fn i ->
        # %{state | merkle_trees:  [MapSet.new()]}
        config = %{config | virtual_node_ring: elem(ExHashRing.Ring.start_link(), 1)}
        a = spawn(String.to_atom("a#{i}"), fn -> Dynamo.become_worker(config, "a#{i}") end)
        pids = nodes
        |> Enum.map fn {x, y} ->
          if x > 1 do
            # IO.puts("y: #{inspect(y)}")
            atom = String.to_atom("#{y}#{i}")

            send(String.to_atom("#{nodes[x-1]}#{i}"), :getConfig)
            config =
            receive do
              # {_, %Dynamo{}} -> %Dynamo{}
              msg -> msg
            after
              5_000 -> assert false
            end

            spawn(atom, fn -> Dynamo.become_worker(config, "#{y}#{i}") end)

          end
        end

        :timer.sleep(50)
        put_node = Enum.random(Map.values(nodes))
        # IO.puts("Round #{i} put node: #{put_node}")
        send(String.to_atom("#{put_node}#{i}"), %Dynamo.PutRequestFromClient{key: "key#{i}", value: 1})

        handle = Process.monitor(a)

        receive do
          {:DOWN, ^handle, _, _, _} -> true

          msg -> 
            # IO.puts("Put response before get #{inspect(msg)}")
            get_node = Enum.random(Map.values(nodes))
            # IO.puts("Round #{i} get node: #{get_node}")
            send(String.to_atom("#{get_node}#{i}"), %Dynamo.GetRequestFromClient{key: "key#{i}"})
            # IO.puts("after sending get")
        after
          30_0000 -> assert false
        end

        receive do
          {:DOWN, ^handle, _, _, _} -> true
          
          %Dynamo.GetResponseToClient{key: key, value: value} ->
            IO.puts("GET response #{i} #{value}")
            value
          msg -> 
            IO.puts("GET response #{i} #{inspect(msg)}")
            # List.insert_at(ans, 0, 0)
        after
          30_0000 -> assert false
        end
        # Enum.each pids, fn p ->
        #   IO.inspect(p)
        #   Process.exit(p, :kill)
        # end
      end
      IO.inspect(ans)
      count = Enum.count(Enum.filter(ans, fn a -> a != nil end))
      IO.puts("Success attemps: #{count}; Success rate: #{count/900}")

      
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
