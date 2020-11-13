defmodule Syslogreader.SysDLogLine do
  alias Syslogreader.SysDLogLine
  #   {

  #     "_GID":"1000",
  #     "_SYSTEMD_INVOCATION_ID":"090db9a9fd374491b946aded95b0ac5e",
  #     "_BOOT_ID":"95c141899a3740e195bbe7276ebc8ba2",
  #     "_CMDLINE":"/home/drex/.cache/pypoetry/virtualenvs/spins-halp-line-TnZF6i6p-py3.8/bin/python /home/drex/spins_halp_line/spins_halp_line/server.py",
  #     "_SYSTEMD_CGROUP":"/system.slice/spins.service",
  #     "_CAP_EFFECTIVE":"0",
  #     "_TRANSPORT":"stdout",
  #     "_MACHINE_ID":"65b0004ab58a40bb83193ccac01a0ad3",
  #     "_UID":"1000",
  #     "__REALTIME_TIMESTAMP":"1605251069512802",
  #     "_SYSTEMD_SLICE":"system.slice",
  #     "__CURSOR":"s=882c1ce4301c4c2c902e8f8dcc531469;i=24ce;b=95c141899a3740e195bbe7276ebc8ba2;m=2fc8f433da;t=5b3f7a3c60c62;x=349a208efb233161",
  #     "_STREAM_ID":"62595e83ea63489ebd9abb43cd82ee13",
  #     "_EXE":"/usr/bin/python3.8",
  #     "_SELINUX_CONTEXT":"unconfined ",
  #     "MESSAGE":"[INFO] 127.0.0.1:53908 -- GET /favicon.ico 1.0 | 404 103",
  #     "SYSLOG_IDENTIFIER":"spins",
  #     "SYSLOG_FACILITY":"3",
  #     "_HOSTNAME":"spins-halp-line",
  #     "PRIORITY":"6",
  #     "_COMM":"python",
  #     "_PID":"105536",
  #     "_SYSTEMD_UNIT":"spins.service",
  #     "__MONOTONIC_TIMESTAMP":"205234910170"

  # }
  # number
  defstruct _GID: "",
            _SYSTEMD_INVOCATION_ID: "",
            _BOOT_ID: "",
            _CMDLINE: "",
            _SYSTEMD_CGROUP: "",
            # number
            _CAP_EFFECTIVE: "",
            _TRANSPORT: "",
            _MACHINE_ID: "",
            # number
            _UID: "",
            # number
            __REALTIME_TIMESTAMP: "",
            _SYSTEMD_SLICE: "",
            __CURSOR: "",
            _STREAM_ID: "",
            _EXE: "",
            _SELINUX_CONTEXT: "",
            MESSAGE: "",
            SYSLOG_IDENTIFIER: "",
            # number
            SYSLOG_FACILITY: "",
            _HOSTNAME: "",
            PRIORITY: "",
            _COMM: "",
            _PID: "",
            _SYSTEMD_UNIT: "",
            # number
            __MONOTONIC_TIMESTAMP: ""

  def new(line) do
    Poison.decode!(line, as: %SysDLogLine{})
  end

  def payload(l = %{MESSAGE: m}) do
    %{"ts" => Map.get(l, :__REALTIME_TIMESTAMP), "line" => m}
    |> Poison.encode!()
  end

  defimpl String.Chars, for: SysDLogLine do
    def to_string(l = %{MESSAGE: m}) do
      "[#{l[:_PID]}] #{m}"
    end
  end
end
