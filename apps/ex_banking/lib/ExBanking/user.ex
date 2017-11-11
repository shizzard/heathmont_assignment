defmodule ExBanking.User do
  @moduledoc """
    An abstraction of user in the system. Data structure contains information
    about user itself and a list of accounts that user holds.
    New accounts are created on-demand.
  """

  alias ExBanking.Type
  alias ExBanking.Account
  alias ExBanking.User

  @type id() :: String.t

  @type t() :: %__MODULE__{
    id: id(),
    accounts: :dict.dict(
      key_t :: Acccount.currency(),
      value_t :: Account.t()
    )
  }
  defstruct [:id, accounts: :dict.new()]


  @spec get_balance(
    user :: t(),
    currency :: Account.currency()
  ) ::
    ret :: Account.amount()

  def get_balance(%User{accounts: accounts}, currency)
  when is_binary(currency) do
    account = get_account(accounts, currency)
    account.amount
  end


  @spec get_operations_count(
    user :: t()
  ) ::
    ret :: non_neg_integer()

  def get_operations_count(%User{accounts: accounts}) do
    :dict.fold(fn(_Currency, account, acc) ->
      acc + Account.operations_count(account)
    end, 0, accounts)
  end


  @spec get_operations_count(
    user :: t(),
    currency :: Account.currency()
  ) ::
    ret :: non_neg_integer()

  def get_operations_count(%User{accounts: accounts}, currency) do
    Account.operations_count(get_account(accounts, currency))
  end


  @spec plan_deposit(
    user :: t(),
    currency :: Account.currency(),
    operation_amount :: Account.amount()
  ) ::
    Type.ok_return(
      ok_t :: {operation :: Operation.t(), user :: t()}
    )

  def plan_deposit(%User{accounts: accounts} = user, currency, operation_amount)
  when is_binary(currency)
  and is_integer(operation_amount)
  and operation_amount >= 0 do
    {:ok, {operation, account}} = Account.plan_deposit(
      get_account(accounts, currency),
      operation_amount
    )
    {:ok, {operation, %{user |
      accounts: set_account(accounts, currency, account)
    }}}
  end


  @spec plan_withdraw(
    user :: t(),
    currency :: Account.currency(),
    operation_amount :: Account.amount()
  ) ::
    Type.generic_return(
      ok_t :: {operation :: Operation.t(), user :: t()},
      error_t :: ExBanking.error_not_enough_money()
    )

  def plan_withdraw(%User{accounts: accounts} = user, currency, operation_amount)
  when is_binary(currency)
  and is_integer(operation_amount)
  and operation_amount >= 0 do
    case Account.plan_withdraw(
      get_account(accounts, currency),
      operation_amount
    ) do
      {:ok, {operation, account}} ->
        {:ok, {operation, %{user |
          accounts: set_account(accounts, currency, account)
        }}}
      {:error, reason} ->
        {:error, reason}
    end
  end


  @spec commit(
    account :: t(),
    currency :: Account.currency(),
    operation :: Operation.t()
  ) ::
    Type.generic_return(
      ok_t :: t(),
      error_t :: Account.error_commit_failed()
    )

  def commit(%User{accounts: accounts} = user, currency, operation) do
    case Account.commit(get_account(accounts, currency), operation) do
      {:ok, account} ->
        {:ok, %{user |
          accounts: set_account(accounts, currency, account)
        }}
      {:error, Reason} ->
        {:error, Reason}
    end
  end


  @spec rollback(
    account :: t(),
    currency :: Account.currency(),
    operation :: Operation.t()
  ) ::
    Type.generic_return(
      ok_t :: t(),
      error_t :: Account.error_rollback_failed()
    )

  def rollback(%User{accounts: accounts} = user, currency, operation) do
    case Account.rollback(get_account(accounts, currency), operation) do
      {:ok, account} ->
        {:ok, %{user |
          accounts: set_account(accounts, currency, account)
        }}
      {:error, Reason} ->
        {:error, Reason}
    end
  end



  @spec get_account(
    accounts :: :dict.dict(
      key_t :: Account.currency(),
      value_t :: Account.account()
    ),
    currency :: Account.currency()
  ) ::
    ret :: Account.account()

  defp get_account(accounts, currency) do
    case :dict.find(currency, accounts) do
      {:ok, account} ->
        account
      :error ->
        %Account{currency: currency}
    end
  end


  @spec set_account(
    accounts :: :dict.dict(
      key_t :: Account.currency(),
      value_t :: Account.account()
    ),
    currency :: Account.currency(),
    account :: Account.account()
  ) ::
    ret :: :dict.dict(
      key_t :: Account.currency(),
      value_t :: Account.account()
    )

  defp set_account(accounts, currency, account) do
    :dict.store(currency, account, accounts)
  end


end
