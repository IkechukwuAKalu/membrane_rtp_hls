defmodule MembraneRtpHls.Utils.AddrPort do
  @moduledoc """
  Defines Store helper methods around addresses and ports
  """
  alias MembraneRtpHls.Utils.KvStore

  @addr_port_key "addr_port_key"
  @joiner "::"

  @doc """
  Returns all host strings or empty list if there's none
  """
  @spec find_all(atom) :: [binary, ...]
  def find_all(store) do
    case KvStore.find(store, @addr_port_key) do
      result when is_list(result) ->
        result

      _ ->
        []
    end
  end

  @doc """
  Adds the address and port record to the store
  """
  @spec register(atom, atom, binary | tuple, integer) :: :ok
  def register(store, id, host, port) do
    host_string = format(id, host, port)
    updated_host_strings = [host_string] ++ find_all(store)

    KvStore.upsert(store, @addr_port_key, updated_host_strings)
  end

  @doc """
  Removes the address and port record from the store if exists
  """
  @spec unregister(atom, atom) :: :ok
  def unregister(store, id) do
    hosts =
      store
      |> find_all()
      |> Enum.filter(fn host_string ->
        [current_id | _] = String.split(host_string, @joiner)

        "#{current_id}" != "#{id}"
      end)

    KvStore.upsert(store, @addr_port_key, hosts)
  end

  @doc """
  Checks if an address and port are in use
  """
  @spec in_use?(atom, atom, binary | tuple, integer) :: boolean
  def in_use?(store, id, host, port) do
    formatted = format(id, host, port)
    addr_port_only = parse(formatted)

    store
    |> find_all()
    |> Enum.find(&(parse(&1) == addr_port_only))
  end

  # This concatenates the process id, host address and port number
  defp format(id, host, port), do: "#{id}#{@joiner}#{inspect(host)}#{@joiner}#{port}"

  # This parses the formatted data to return only the host and port
  defp parse(text) do
    [_ | addr_and_port] = String.split(text, @joiner)

    Enum.join(addr_and_port, @joiner)
  end
end
