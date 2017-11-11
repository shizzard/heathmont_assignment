defmodule ExBanking.Account do
  @moduledoc """
    An absraction of user account in the system. Account here is amount of
    money of some known currency that user holds. Data structure contains
    information about account currency, amount of money and a list of active
    operations.
  """
  alias ExBanking.Type
  alias ExBanking.Operation
  alias ExBanking.Account

  @type error_commit_failed() :: :commit_failed
  @type error_rollback_failed() :: :rollback_failed
  @type error() :: error_commit_failed() | error_rollback_failed()

  @type currency() :: String.t()
  @type amount() :: non_neg_integer()

  @type t() :: %__MODULE__{
    currency: currency(),
    amount: amount(),
    operations: [Operation.t()]
  }
  defstruct [:currency, amount: 0, operations: []]


  @spec operations_count(
    account :: t()
  ) ::
    ret :: non_neg_integer()

  def operations_count(%Account{operations: operations}) do
    length(operations)
  end


  @spec plan_deposit(
    account :: t(),
    operation_amount :: amount()
  ) ::
    Type.ok_return(
      ok_t :: {operation :: Operation.t(), account :: t()}
    )

  def plan_deposit(%Account{} = account, operation_amount)
  when is_integer(operation_amount)
  and operation_amount >= 0 do
    maybe_plan_deposit(account, operation_amount)
  end


  @spec plan_withdraw(
    account :: t(),
    operation_amount :: amount()
  ) ::
    Type.ok_return(
      ok_t :: {operation :: Operation.t(), account :: t()}
    )

  def plan_withdraw(%Account{} = account, operation_amount)
  when is_integer(operation_amount)
  and operation_amount >= 0 do
    maybe_plan_withdraw(account, operation_amount)
  end


  @spec commit(
    account :: t(),
    operation :: Operation.t()
  ) ::
    Type.generic_return(
      ok_t :: t(),
      error_t :: error_commit_failed()
    )

  def commit(%Account{} = account, %Operation{} = operation) do
    maybe_commit(account, operation.id, operation.type)
  end


  @spec rollback(
    account :: t(),
    operation :: Operation.t()
  ) ::
    Type.generic_return(
      ok_t :: t(),
      error_t :: error_rollback_failed()
    )

  def rollback(%Account{} = account, %Operation{} = operation) do
    maybe_rollback(account, operation.id, operation.type)
  end



  @spec maybe_plan_deposit(
    account :: t(),
    operation_amount :: non_neg_integer()
  ) ::
    Type.ok_return(
      ok_t :: {operation :: Operation.t(), account :: t()}
    )

  defp maybe_plan_deposit(%Account{operations: operations} = account, operation_amount) do
    operation = %Operation{id: make_ref(), type: :deposit, amount: operation_amount}
    {:ok, {
      operation,
      %{account | operations: [operation | operations]}
    }}
  end


  @spec maybe_plan_withdraw(
    account :: t(),
    operation_amount :: non_neg_integer()
  ) ::
    Type.generic_return(
      ok_t :: {operation :: Operation.t(), account :: t()},
      error_t :: ExBanking.error_not_enough_money()
    )

  defp maybe_plan_withdraw(%Account{amount: amount, operations: operations} = account, operation_amount)
  when amount >= operation_amount do
    operation = %Operation{id: make_ref(), type: :withdraw, amount: operation_amount}
    {:ok, {
      operation,
      %{account | amount: amount - operation_amount, operations: [operation | operations]}
    }}
  end

  defp maybe_plan_withdraw(_account, _operation_amount) do
    {:error, :not_enough_money}
  end


  @spec maybe_commit(
    account :: t(),
    operation_id :: Operation.id(),
    operation_type :: Operation.type()
  ) ::
    Type.generic_return(
      ok_t :: t(),
      error_t :: error_commit_failed()
    )

  defp maybe_commit(%Account{} = account, operation_id, :deposit) do
    maybe_add_operation_amount(account, operation_id, :commit_failed)
  end

  defp maybe_commit(%Account{} = account, operation_id, :withdraw) do
    maybe_drop_operation(account, operation_id, :commit_failed)
  end


  @spec maybe_rollback(
    account :: t(),
    operation_id :: Operation.id(),
    operation_type :: Operation.type()
  ) ::
    Type.generic_return(
      ok_t :: t(),
      error_t :: error_rollback_failed()
    )

  defp maybe_rollback(%Account{} = account, operation_id, :deposit) do
    maybe_drop_operation(account, operation_id, :rollback_failed)
  end

  defp maybe_rollback(%Account{} = account, operation_id, :withdraw) do
    maybe_add_operation_amount(account, operation_id, :rollback_failed)
  end


  @spec maybe_drop_operation(
    account :: t(),
    operation_id :: Operation.id(),
    error_code :: error()
  ) ::
    Type.generic_return(
      ok_t :: t(),
      error_t :: error()
    )

  defp maybe_drop_operation(%Account{operations: operations} = account, operation_id, error_code) do
    predicate = match_operation_id_predicate(operation_id)
    case :lists.partition(predicate, operations) do
      {[], ^operations} ->
        {:error, error_code}
      {[_operation], operations} ->
        {:ok, %{account | operations: operations}}
    end
  end


  @spec maybe_add_operation_amount(
    account :: t(),
    operation_id :: Operation.id(),
    error_code :: error()
  ) ::
    Type.generic_return(
      ok_t :: t(),
      error_t :: error()
    )

  defp maybe_add_operation_amount(%Account{amount: amount, operations: operations} = account, operation_id, error_code) do
    predicate = match_operation_id_predicate(operation_id)
    case :lists.partition(predicate, operations) do
      {[], ^operations} ->
        {:error, error_code}
      {[operation], operations} ->
        {:ok, %{account | amount: amount + operation.amount, operations: operations}}
    end
  end


  @spec match_operation_id_predicate(
    operation_id :: Operation.id()
  ) ::
    ret :: (operation :: Operation.t() -> boolean())

  defp match_operation_id_predicate(operation_id) do
    fn(operation) -> operation_id == operation.id end
  end

end
