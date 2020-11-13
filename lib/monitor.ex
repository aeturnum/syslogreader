defmodule Syslogreader.Monitor do
  use GenServer
  alias Syslogreader.SysDLogLine

  # Callbacks
  @name Monitor

  @key :listeners
  @limit 100

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
      # IO.puts("Sending #{line} to #{inspect(self())}")
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
    # IO.puts("adding line: #{line}")
    with line <- SysDLogLine.new(line) do
      notify_all(line)
      {:noreply, {[line | lines] |> Enum.take(@limit), task}}
    end
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
      for {pid, _} <- entries do
        notify(pid, line)
      end
    end)

    line
  end

  defp notify(pid, line) do
    Process.send(pid, SysDLogLine.payload(line) |> IO.inspect(label: "notify"), [])
  end

  # task section where we monitor the command line
  defp make_task() do
    Task.async(fn ->
      do_ping()
    end)
  end

  def do_ping(), do: listen(make_p_proc(), nil)

  defp make_p_proc() do
    # make is json
    with command <- "journalctl -f -q -o json -t spins" do
      {:ok, exexec_pid, spawner_os_pid} = Exexec.run(command, stdout: true, stderr: :stdout)

      {exexec_pid, spawner_os_pid}
    end
  end

  defp listen(pids = {_, spawner_os_pid}, old_orphan) do
    # todo: re-write this to be simpler and just re-send messages to ourselves
    receive do
      {:stdout, ^spawner_os_pid, data} ->
        # {^pid, :data, :out, data} ->
        new_orphan =
          data
          |> String.split("\n", trim: true)
          |> Enum.reduce(
            old_orphan,
            fn line, orphan ->
              if String.contains?(line, "{") and String.contains?(line, "}") do
                add_line(line)
                # kick can down road
                orphan
              else
                case orphan do
                  nil ->
                    # new orphan
                    line

                  partial ->
                    # consume orphan
                    add_line(partial <> line)
                    nil
                end
              end
            end
          )

        listen(pids, new_orphan)

      {:stderr, ^spawner_os_pid, _data} ->
        listen(pids, old_orphan)

      _other ->
        {:ok, nil}
    end
  end
end
