defmodule Syslogreader.Monitor do
  use GenServer

  # Callbacks
  @name Monitor

  @key :listeners
  @limit 30

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: @name)
  end

  def add_line(line) do
    GenServer.cast(@name, {:add, line})
  end

  def get_backlog() do
    IO.puts("get_backlog")

    GenServer.call(@name, :scrollback)
    |> IO.inspect(label: "backlog")
    |> Enum.each(fn line ->
      IO.puts("Sending #{line} to #{inspect(self())}")
      notify(self(), line)
    end)
  end

  def register() do
    Registry.Syslogreader
    |> Registry.register(@key, {})
  end

  def init(_) do
    {:ok, {[], make_task()}}
  end

  def handle_cast({:add, line}, {lines, task}) do
    IO.puts("adding line: #{line}")
    notify_all(line)
    {:noreply, {[line | lines] |> Enum.take(@limit), task}}
  end

  def handle_cast(other, state) do
    IO.puts("unexpected cast: #{inspect(other)}")
    {:noreply, state}
  end

  def handle_call(:scrollback, _from, {lines, task}) do
    {:reply, lines |> Enum.reverse(), {lines, task}}
  end

  def handle_call(_, _from, state) do
    {:reply, nil, state}
  end

  defp notify_all(line) do
    Registry.Syslogreader
    |> Registry.dispatch(@key, fn entries ->
      IO.inspect(entries, label: "entries")

      for {pid, _} <- entries do
        notify(pid, line)
      end
    end)

    line
  end

  defp notify(pid, line) do
    Process.send(pid, line, [])
  end

  # task section where we monitor the command line
  defp make_task() do
    Task.async(fn ->
      do_ping()
    end)
  end

  def do_ping(), do: listen(make_p_proc())

  defp make_p_proc() do
    {:ok, exexec_pid, spawner_os_pid} =
      Exexec.run("journalctl -f -q -t spins", stdout: true, stderr: :stdout)

    # {:ok, exexec_pid, spawner_os_pid} = Exexec.run("ping 8.8.8.8", stdout: true, stderr: :stdout)

    {exexec_pid, spawner_os_pid}
  end

  defp listen(pids = {_, spawner_os_pid}) do
    # todo: re-write this to be simpler and just re-send messages to ourselves
    receive do
      {:stdout, ^spawner_os_pid, data} ->
        # {^pid, :data, :out, data} ->
        data
        |> String.split("\n", trim: true)
        |> add_line()

        listen(pids)

      {:stderr, ^spawner_os_pid, _data} ->
        listen(pids)

      _other ->
        {:ok, nil}
    end
  end
end
