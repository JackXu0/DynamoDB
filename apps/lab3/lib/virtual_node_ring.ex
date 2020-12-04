defmodule Dynamo.VirtualNodeRing do

  alias __MODULE__

  defstruct(
    ring: {}
  )

  @spec put(%VirtualNodeRing{}, %VirtualNode{}) :: %VirtualNodeRing{}
  def put(state, vn) do
    %{state | ring:  Map.put(ring, vn.hash, vn)}
  end

  # TODO: add method getVirtualNodeHashArray


end