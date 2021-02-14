defmodule MembraneRtpHls.Application do
  @moduledoc """
  This is the application entry moudle.

  It starts a Dynamic Supervisor which adds children (stream sessions)
  to it, or removes from it. It also starts a key-value store - this KV
  implementation can be replaced with any preferred tool.
  """
  use Application

  require Logger

  alias MembraneRtpHls.Utils.KvStore
  alias MembraneRtpHls.Utils.AddrPort

  @dynamic_supervisor MembraneRtpHls.DynamicSupervisor
  @store_process KvStore.process_name()

  @impl true
  @spec start(any, any) :: {:error, any} | {:ok, pid}
  def start(_type, _args) do
    children = [
      {KvStore, [name: @store_process]},
      {DynamicSupervisor, strategy: :one_for_one, name: @dynamic_supervisor}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  @doc """
  Starts a new Pipeline Session Process.

  param `opts` should be of the format below:
    [
      pipeline_opts: [
        port: udp_port,
        host: udp_host,
        storage_type: :file | :gcs
      ],
      gcs_opts: [
        bucket: bucket_name,
        folder: folder_name
      ]
    ]
  NOTE: The `gcs_opts` is only used when the storage type is :gcs
  """
  @spec start_session(keyword, atom) :: :ignore | {:error, any} | {:ok, pid} | {:ok, pid, any}
  def start_session(opts, session_process) do
    udp_host = opts[:pipeline_opts][:host]
    udp_port = opts[:pipeline_opts][:port]

    if is_nil(udp_host) or is_nil(udp_port) do
      raise %ArgumentError{message: "UDP host and port need to be specified"}
    end

    if AddrPort.in_use?(@store_process, session_process, udp_host, udp_port) do
      Logger.error("The UDP address and port are already in use")
      {:error, :eaddrinuse}
    else
      opts
      |> Keyword.merge(name: session_process)
      |> do_start_child()
    end
  end

  # This starts the session as a child of the dynamic supervisor
  defp do_start_child(opts) do
    udp_host = opts[:pipeline_opts][:host]
    udp_port = opts[:pipeline_opts][:port]
    session_process = opts[:name]

    child_spec = %{
      id: session_process,
      start: {MembraneRtpHls.Session, :start_link, [opts]},
      restart: :transient,
      type: :supervisor
    }

    case DynamicSupervisor.start_child(@dynamic_supervisor, child_spec) do
      :ignore ->
        :ignore

      {:error, message} = result ->
        Logger.error("Dynamic supervisor error: #{inspect(message)}")
        result

      {:ok, _} = result ->
        AddrPort.register(@store_process, session_process, udp_host, udp_port)
        result

      {:ok, _, _} = result ->
        AddrPort.register(@store_process, session_process, udp_host, udp_port)
        result
    end
  end

  @doc """
  Stops a Pipeline Session Process.

  param `session_process` is the process id/name for the Session Supervisor
  """
  @spec stop_session(atom, any) :: :ok
  def stop_session(session_process, reason \\ :normal) do
    :ok = Supervisor.stop(session_process, reason)

    AddrPort.unregister(@store_process, session_process)
  end
end
