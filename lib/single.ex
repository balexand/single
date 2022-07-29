defmodule Single do
  @moduledoc """
  Singleton watchdog process
  Each node that the singleton runs on, runs this process. It is
  responsible for starting the singleton process (with the help of
  Erlang's 'global' module).
  When starting the singleton process fails, it instead monitors the
  process, so that in case it dies, it will try to start it locally.
  The singleton process is started using the `GenServer.start_link`
  call, with the given module and args.
  """

  use GenServer, restart: :transient

  @doc """
  Like `start_link/4`, except without link.
  """
  def start(mod, args, name, opts \\ []) do
    GenServer.start(__MODULE__, [mod, args, name], opts)
  end

  @doc """
  Start the manager process, registering it under a unique name.
  """
  def start_link(mod, args, name, opts \\ []) do
    GenServer.start_link(__MODULE__, [mod, args, name], opts)
  end

  defmodule State do
    @moduledoc false
    defstruct pid: nil, mod: nil, args: nil, name: nil
  end

  @doc false
  def init([mod, args, name]) do
    state = %State{mod: mod, args: args, name: name}
    {:ok, restart(state)}
  end

  @doc false
  def handle_info({:DOWN, _, :process, pid, :normal}, state = %State{pid: pid}) do
    # Managed process exited normally. Shut manager down as well.
    {:stop, :normal, state}
  end

  def handle_info({:DOWN, _, :process, pid, _reason}, state = %State{pid: pid}) do
    # Managed process exited with an error. Try restarting, after a delay
    Process.sleep(:rand.uniform(5_000) + 5_000)
    {:noreply, restart(state)}
  end

  defp restart(state) do
    pid =
      case state.mod.start_link(state.args, name: {:global, state.name}) do
        {:ok, pid} -> pid
        {:error, {:already_started, pid}} -> pid
      end

    Process.monitor(pid)
    %State{state | pid: pid}
  end
end
