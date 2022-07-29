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

    def handle_call({:stop, reason}, _from, state) do
      {:stop, reason, :ok, state}
    end
  end

  test "starts child GenServer" do
    assert {:ok, _pid} = Single.start_link(ExampleServer, :thearg, :example)

    assert GenServer.call({:global, :example}, :ping) == :pong
  end

  test "manager exits with :normal when child process exits with :normal" do
    assert {:ok, pid} = Single.start_link(ExampleServer, :thearg, :example)

    child_pid = :global.whereis_name(:example)
    assert Process.alive?(pid)
    assert Process.alive?(child_pid)

    Process.monitor(pid)

    assert GenServer.call({:global, :example}, {:stop, :normal}) == :ok
    refute Process.alive?(child_pid)

    assert_receive {:DOWN, _ref, :process, ^pid, :normal}
  end
end
