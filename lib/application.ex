defmodule MembraneRtpHls.Application do
  @moduledoc """
  This is the application entry moudle.

  It starts a Dynamic Supervisor which adds children (stream sessions)
  to it, or removes from it
  """
  use Application

  require Logger

  @dynamic_supervisor MembraneRtpHls.DynamicSupervisor

  @impl true
  def start(_type, _args) do
    children = [
      {DynamicSupervisor, strategy: :one_for_one, name: @dynamic_supervisor}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  @doc """
  Creates a new Pipeline session
  """
  @spec new_session(keyword) :: :ignore | {:error, any} | {:ok, pid} | {:ok, pid, any}
  def new_session(opts) do
    child_spec = {MembraneRtpHls.Session, opts}

    DynamicSupervisor.start_child(@dynamic_supervisor, child_spec)
  end

  @doc """
  Creates a new pipeline session listening on a random port
  """
  @spec new_session :: any
  def new_session do
    port = 5000

    [
      gcs_opts: [bucket: "membrane_streams", folder: "new_aa"],
      pipeline_opts: [port: port, host: {127, 0, 0, 1}, storage_type: :file]
    ]
    |> new_session()
    |> case do
      {:ok, _} ->
        Logger.info("New session added to Dynamic Supervisor")
        port

      {:ok, _, _} ->
        Logger.info("New session added to Dynamic Supervisor")
        port

      reason ->
        reason = inspect(reason)

        Logger.error(reason)
        {:error, reason}
    end

    port
  end
end
