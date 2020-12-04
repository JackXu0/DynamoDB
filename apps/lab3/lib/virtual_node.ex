defmodule Dynamo.VirtualNode do

  alias __MODULE__

  defstruct(
    worker: nil,
    hash: nil,
    partition: nil
  )

  #@spec new(atom(),
  #        atom(),
  #        non_neg_integer()) :: %VirtualNode{}
  def new(w, h, p) do
    IO.puts(5555555)
    %VirtualNode{
      worker: w,
      hash: h,
      partition: p
    }
  end
end