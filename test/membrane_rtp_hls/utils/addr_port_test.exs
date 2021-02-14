defmodule MembraneRtpHls.Utils.AddrPortTest do
  use ExUnit.Case, async: true

  alias MembraneRtpHls.Utils.{AddrPort, KvStore}

  describe "address port context:" do
    @port 5000
    @host {127, 0, 0, 1}

    setup do
      store = start_supervised!(KvStore)

      %{store: store}
    end

    test "returns all address-ports", %{store: store} do
      AddrPort.register(store, :first, @host, @port)
      AddrPort.register(store, :second, @host, @port)

      assert length(AddrPort.find_all(store)) == 2
    end

    test "registers an address-port", %{store: store} do
      assert :ok == AddrPort.register(store, :first, @host, @port)
      assert length(AddrPort.find_all(store)) == 1
    end

    test "unregisters an address-port", %{store: store} do
      key = :first

      # Register the address-port
      assert :ok == AddrPort.register(store, key, @host, @port)
      assert length(AddrPort.find_all(store)) == 1

      # Unregister the address-port
      assert :ok == AddrPort.unregister(store, key)
      assert length(AddrPort.find_all(store)) == 0
    end

    test "check if an address-port has been registered", %{store: store} do
      AddrPort.register(store, :first, @host, @port)

      assert AddrPort.in_use?(store, :first, @host, @port)
      refute AddrPort.in_use?(store, :second, {192, 168, 43, 1}, 33455)
    end
  end
end
