defmodule Peek.DeferrableTest do
  use ExUnit.Case, async: true

  alias Peek.Deferrable

  describe "defer/1" do
    test "executes the given function immediately if not inside a transaction" do
      assert "hello" == Deferrable.defer(fn -> "hello" end)
    end
  end

  describe "process_deferred/0" do
    test "does nothing if not inside a transaction" do
      assert [] == Deferrable.process_deferred()
    end
  end

  describe "transaction/1" do
    test "defers execution of the given function until after the transaction completes" do
      Deferrable.transaction(fn ->
        Deferrable.defer(fn -> send(self(), :hello) end)

        refute_received :hello

        {:ok, "result"}
      end)

      assert_received :hello
    end

    test "allows calls to process_deferred/0 to execute all deferred functions to this point" do
      Deferrable.transaction(fn ->
        Deferrable.defer(fn -> "hello" end)
        Deferrable.defer(fn -> "world" end)

        assert ["hello", "world"] == Deferrable.process_deferred()

        Deferrable.defer(fn -> send(self(), :goodbye) end)

        {:ok, :ok}
      end)

      assert_received :goodbye
    end

    test "can clear all deferred functions to this point" do
      Deferrable.transaction(fn ->
        Deferrable.defer(fn -> "hello" end)
        Deferrable.defer(fn -> raise "world" end)
        Deferrable.clear_deferred()

        assert [] == Deferrable.process_deferred()

        {:ok, "result"}
      end)
    end

    test "raising in a deferred function clears all subsequent deferred functions" do
      Deferrable.transaction(fn ->
        Deferrable.defer(fn -> raise "hello" end)
        Deferrable.defer(fn -> send(self(), :world) end)

        assert_raise RuntimeError, "hello", fn ->
          Deferrable.process_deferred()
        end

        refute_received :world

        {:ok, "result"}
      end)
    end

    test "handles nested transactions" do
      Deferrable.transaction(fn ->
        Deferrable.defer(fn -> send(self(), :level1) end)

        Deferrable.transaction(fn ->
          Deferrable.defer(fn -> send(self(), :level2) end)

          {:ok, _} =
            Deferrable.transaction(fn ->
              Deferrable.defer(fn -> send(self(), :level3) end)

              {:ok, "whatever"}
            end)

          _error_ignored =
            Deferrable.transaction(fn ->
              Deferrable.defer(fn -> send(self(), :level3_failed) end)

              {:error, "oh no!"}
            end)

          {:ok, "whatever"}
        end)

        {:ok, "whatever"}
      end)

      assert_received :level1
      assert_received :level2
      assert_received :level3
      refute_received :level3_failed
    end

    test "transaction success" do
      assert {:ok, "something"} ==
               Deferrable.transaction(fn ->
                 Deferrable.defer(fn -> send(self(), :hello) end)
                 {:ok, "something"}
               end)

      assert_received :hello
    end

    test "transaction failure" do
      assert {:error, "oh no!"} ==
               Deferrable.transaction(fn ->
                 Deferrable.defer(fn -> send(self(), :hello) end)
                 {:error, "oh no!"}
               end)

      refute_received :hello
    end

    test "transaction raise" do
      assert_raise RuntimeError, "oh no!", fn ->
        Deferrable.transaction(fn ->
          Deferrable.defer(fn -> send(self(), :hello) end)
          raise "oh no!"
        end)
      end

      refute_received :hello
    end
  end
end
