defmodule Dynamo.VirtualNode do

  alias __MODULE__

  defstruct(
    worker: nil,
    hash: nil,
    partition: nil
  )

  @spec new(%Dynamo{},
          atom(),
          non_neg_integer()) :: %VirtualNode{}
  def new(worker, hash, partition) do
    %VirtualNode{
      worker: worker,
      hash: hash,
      partition: partition
    }
  end
end