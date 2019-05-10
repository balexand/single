defmodule Single do
  @moduledoc """
  Manager process that starts and watches a singleton process. This process should be started on
  each node that the singleton process will be run on. The Erlang
  [`:global` module](http://erlang.org/doc/man/global.html) is responsible for ensuring that there
  are not duplicate instances of the singleton process within the cluster.

  If the singleton process has not already been started then it will be started and linked to the
  manager process. If the singleton process exits for any reason, whether `:normal` or otherwise,
  then the `Single` process will exit with the same reason. If the manager process exits with a
  reason other than `:normal` then the singleton process will exit with the same reason.

  If the singleton process is already started then the manager process will monitor it. If the
  remote singleton process exits for any reason then the manager process will try to start it
  again.
  """

  use GenServer

  defmodule State do
    @moduledoc false
    defstruct [:init_arg, :module, :name, :ref, :ref_type]
  end

  def start(module, init_arg, name, options \\ []) do
    state = %State{init_arg: init_arg, module: module, name: name}
    GenServer.start(__MODULE__, state, options)
  end

  def start_link(module, init_arg, name, options \\ []) do
    state = %State{init_arg: init_arg, module: module, name: name}
    GenServer.start_link(__MODULE__, state, options)
  end

  ###
  # GenServer callbacks
  ###

  @doc false
  def init(%State{} = state) do
    {:ok, start_child(state)}
  end

  @doc false
  def handle_info({:DOWN, ref, :process, _, :normal}, %State{ref: ref, ref_type: :local} = state) do
    # Local process exited normally. This process should do the same.
    {:stop, :normal, state}
  end

  def handle_info({:DOWN, ref, :process, _, _reason}, %State{ref: ref, ref_type: :local} = state) do
    # Local process exited with reason other than :normal. Process linking will take care of this.
    {:noreply, state}
  end

  def handle_info({:DOWN, ref, :process, _, _reason}, %State{ref: ref, ref_type: :remote} = state) do
    # Remote process exited. Try starting a new process.
    {:noreply, start_child(state)}
  end

  @doc false
  defp start_child(%State{init_arg: init_arg, module: module, name: name} = state) do
    case GenServer.start_link(module, init_arg, name: {:global, name}) do
      {:ok, pid} ->
        %{state | ref: Process.monitor(pid), ref_type: :local}

      {:error, {:already_started, pid}} ->
        %{state | ref: Process.monitor(pid), ref_type: :remote}
    end
  end
end
