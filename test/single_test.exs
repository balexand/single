defmodule SingleTest do
  use ExUnit.Case, async: true
  doctest Single

  import ExUnit.CaptureLog

  defmodule TestServer do
    use GenServer

    def get_state(pid) do
      GenServer.call(pid, :get_state)
    end

    ###
    # GenServer callbacks
    ###
    def init(state) do
      {:ok, state}
    end

    def handle_call(:get_state, _from, state) do
      {:reply, state, state}
    end
  end

  test "test TestServer" do
    {:ok, pid} = GenServer.start_link(TestServer, "it works")
    assert TestServer.get_state(pid) == "it works"
  end

  test "starts managed process" do
    {:ok, _pid} = Single.start_link(TestServer, "test state", :my_singleton)
    assert TestServer.get_state({:global, :my_singleton}) == "test state"
  end

  test "with existing, unmanaged process" do
    {:ok, existing_pid} =
      GenServer.start_link(TestServer, "existing", name: {:global, :my_singleton})

    {:ok, _pid} = Single.start_link(TestServer, "new", :my_singleton)

    assert :global.whereis_name(:my_singleton) == existing_pid
    assert TestServer.get_state({:global, :my_singleton}) == "existing"

    # Stop the existing process and the new singleton will be started
    GenServer.stop(existing_pid)
    assert :global.whereis_name(:my_singleton) == :undefined
    :timer.sleep(100)
    assert TestServer.get_state({:global, :my_singleton}) == "new"
  end

  test "failover from one Single to another" do
    {:ok, _pid} = Single.start_link(TestServer, "first", :my_singleton)
    {:ok, _pid} = Single.start_link(TestServer, "second", :my_singleton)

    assert TestServer.get_state({:global, :my_singleton}) == "first"
    GenServer.stop({:global, :my_singleton})
    :timer.sleep(100)

    assert TestServer.get_state({:global, :my_singleton}) == "second"
  end

  test "shutting down Single shuts down managed process" do
    {:ok, parent} = Single.start(TestServer, "first", :the_process)
    pid = :global.whereis_name(:the_process)
    ref = Process.monitor(pid)

    GenServer.stop(parent, :shutdown)

    assert_receive {:DOWN, ^ref, :process, ^pid, :shutdown}
  end

  test "stopping managed process with :normal stops Single with same reason" do
    {:ok, pid} = Single.start_link(TestServer, "first", :the_process)
    ref = Process.monitor(pid)
    GenServer.stop({:global, :the_process}, :normal)

    assert_receive {:DOWN, ^ref, :process, ^pid, :normal}
  end

  test "stopping managed process with :shutdown stops Single with same reason" do
    {:ok, pid} = Single.start(TestServer, "first", :the_process)
    ref = Process.monitor(pid)
    GenServer.stop({:global, :the_process}, :shutdown)

    assert_receive {:DOWN, ^ref, :process, ^pid, :shutdown}
  end

  test "stopping managed process with :kill stops Single with same reason" do
    {:ok, pid} = Single.start(TestServer, "first", :the_process)
    ref = Process.monitor(pid)

    log =
      capture_log(fn ->
        GenServer.stop({:global, :the_process}, :kill)
      end)

    assert log =~ "[error] GenServer :the_process terminating"
    assert log =~ "** (stop) :kill"

    assert_receive({:DOWN, ^ref, :process, ^pid, :kill})
  end

  test "stopping managed process with :custom_reason stops Single with same reason" do
    {:ok, pid} = Single.start(TestServer, "first", :the_process)
    ref = Process.monitor(pid)

    log =
      capture_log(fn ->
        GenServer.stop({:global, :the_process}, :custom_reason)
      end)

    assert log =~ "[error] GenServer :the_process terminating"
    assert log =~ "** (stop) :custom_reason"

    assert_receive({:DOWN, ^ref, :process, ^pid, :custom_reason})
  end
end
