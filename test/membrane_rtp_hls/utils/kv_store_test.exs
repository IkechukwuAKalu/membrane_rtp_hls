defmodule MembraneRtpHls.Utils.KvStoreTest do
  use ExUnit.Case, async: true

  alias MembraneRtpHls.Utils.KvStore

  describe "store context:" do
    setup do
      store = start_supervised!(KvStore)

      %{store: store}
    end

    test "returns its process name as an atom" do
      assert is_atom(KvStore.process_name())
    end

    test "finds a record in the store", %{store: store} do
      key1 = "super"
      value1 = "secret"
      key2 = "nothing"

      # Create the data
      KvStore.upsert(store, key1, value1)

      # Find the newly created data
      assert KvStore.find(store, key1) == value1
      assert is_nil(KvStore.find(store, key2))
    end

    test "creates a record in the store if it doesn't exist", %{store: store} do
      key = "super"

      # Fetch the data to see if it exists
      assert is_nil(KvStore.find(store, key))

      # Create the data
      assert :ok == KvStore.upsert(store, key, "secret")
      assert is_binary(KvStore.find(store, key))
    end

    test "updates a record in the store if it already exists", %{store: store} do
      key = "super"
      value = "secret"
      new_value = "new_secret"

      # Create the data
      KvStore.upsert(store, key, value)
      assert KvStore.find(store, key) == value

      # Update the data
      assert :ok == KvStore.upsert(store, key, new_value)
      assert KvStore.find(store, key) == new_value
    end

    test "removes a record from the store", %{store: store} do
      key = "super"
      value = "secret"

      # Create the data
      KvStore.upsert(store, key, value)
      assert KvStore.find(store, key) == value

      # Remove the data
      assert :ok == KvStore.remove(store, key)

      # Ensure the data has been removed
      assert is_nil(KvStore.find(store, key))
    end
  end
end
