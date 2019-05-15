defmodule Peek.Deferrable do
  @moduledoc """
  Allows deferring of function calls until a transaction succeeds.

  ## Example

      Deferrable.transaction(fn ->
        Deferrable.defer(fn -> "do something later" end)

        {:ok, "result"}
      end)
  """

  @stack_key :deferrable_stack

  def defer(fun) do
    case stack_ref() do
      :no_stack -> fun.()
      ref -> send(self(), {:deferred, ref, fun})
    end
  end

  def transaction(fun) do
    stack = push_stack(make_ref())

    try do
      result =
        case {stack, fun.()} do
          {[_top], {:ok, result}} ->
            process_deferred()
            {:ok, result}

          {_stack, {:ok, result}} ->
            {:ok, result}

          {_stack, {:error, reason}} ->
            clear_deferred(stack)
            {:error, reason}
        end

      result
    rescue
      err ->
        clear_deferred(stack)

        reraise(err, __STACKTRACE__)
    after
      pop_stack()
    end
  end

  def process_deferred, do: do_process_deferred([])

  defp do_process_deferred(results) do
    receive do
      {:deferred, _ref, fun} ->
        try do
          do_process_deferred([fun.() | results])
        rescue
          # FIXME: Don't clear all later deferred functions when one fails. e.g. losing availability messages
          # if another message fails to publish. Running the deferred functions inside tasks could be a way to solve
          # this, so each one can fail on its own, raise, and have its own stack-trace.
          err ->
            clear_deferred()
            reraise(err, __STACKTRACE__)
        end
    after
      0 -> Enum.reverse(results)
    end
  end

  def clear_deferred do
    case stack() do
      :no_stack -> :ok
      stack -> clear_deferred(stack)
    end
  end

  defp clear_deferred([]), do: :ok

  defp clear_deferred([ref | _rest] = stack) do
    child_tree = get_in(tree(), Enum.reverse(stack))
    child_refs = all_keys(child_tree)
    do_clear_deferred([ref | child_refs])
  end

  defp do_clear_deferred([]), do: :ok

  defp do_clear_deferred([ref | rest] = refs) do
    receive do
      {:deferred, ^ref, _fun} -> do_clear_deferred(refs)
    after
      0 -> do_clear_deferred(rest)
    end
  end

  defp stack_ref do
    case Process.get(@stack_key, :no_stack) do
      {[ref | _rest], _popped} -> ref
      {[], _popped} -> :no_stack
      :no_stack -> :no_stack
    end
  end

  defp stack do
    with {stack, _tree} <- Process.get(@stack_key, :no_stack) do
      stack
    end
  end

  defp tree do
    with {_stack, tree} <- Process.get(@stack_key, :no_stack) do
      tree
    end
  end

  defp push_stack(ref) do
    {stack, tree} = Process.get(@stack_key, {[], %{}})
    stack = [ref | stack]
    tree = put_in(tree, Enum.reverse(stack), %{})
    Process.put(@stack_key, {stack, tree})
    stack
  end

  defp pop_stack do
    with {[_ref | rest], tree} <- Process.get(@stack_key, :no_stack) do
      Process.put(@stack_key, {rest, tree})
      :ok
    else
      {[], _} -> {:error, :top_of_stack}
    end
  end

  defp all_keys(map) do
    Enum.flat_map(map, fn {key, child_map} ->
      [key | all_keys(child_map)]
    end)
  end
end
