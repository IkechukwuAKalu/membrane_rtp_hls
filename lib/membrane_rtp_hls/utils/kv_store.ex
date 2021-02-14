defmodule MembraneRtpHls.Utils.KvStore do
  @moduledoc """
  This module provides an implementation for a key-value store
  """
  use Agent

  @doc """
  Initializes the store
  """
  @spec start_link(keyword) :: {:error, {:already_started, pid} | term} | {:ok, pid}
  def start_link(opts), do: Agent.start_link(fn -> %{} end, opts)

  @doc """
  Returns a specific process name to ensure consistency across modules
  """
  @spec process_name :: atom
  def process_name, do: __MODULE__

  @doc """
  Returns a value from the store if the key exists, else it returns `nil`
  """
  @spec find(atom | pid, binary | integer) :: any
  def find(store, key), do: Agent.get(store, &Map.get(&1, key))

  @doc """
  Updates a record in the store if it exists, else it creates the record
  """
  @spec upsert(atom | pid, binary | integer, any) :: :ok
  def upsert(store, key, value), do: Agent.update(store, &Map.put(&1, key, value))

  @doc """
  Removes a record from the store
  """
  @spec remove(atom | pid, binary | integer) :: :ok
  def remove(store, key) do
    Agent.get_and_update(store, &Map.pop(&1, key))
    :ok
  end
end
