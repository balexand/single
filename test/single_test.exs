defmodule SingleTest do
  use ExUnit.Case, async: true
  doctest Single

  defmodule ExampleServer do
    use GenServer

    def start_link(init_arg, opts) do
      GenServer.start_link(__MODULE__, init_arg, opts)
    end

    @impl true
    def init(:thearg) do
      {:ok, %{}}
    end

    @impl true
    def handle_call(:ping, _from, state) do
      {:reply, :pong, state}
    end
  end

  test "starts child GenServer" do
    assert {:ok, _pid} = Single.start_link(ExampleServer, :thearg, :example)

    assert GenServer.call({:global, :example}, :ping) == :pong
  end
end
