defmodule ExBanking.Shard do
  use GenServer
  require Logger
  alias ExBanking.Type
  alias ExBanking.Operation
  alias ExBanking.Account
  alias ExBanking.User


  @spec shard_id_to_atom(
    shard_id :: non_neg_integer()
  ) ::
    ret :: atom()

  def shard_id_to_atom(shard_id)
  when is_integer(shard_id)
  and shard_id > 0 do
    :io_lib.format("ex_banking_shard-~p", [shard_id])
    |> List.flatten
    |> List.to_atom
  end


  @spec create_user(
    shard :: atom(),
    user_id :: User.id()
  ) ::
    Type.generic_return(
      error_t ::
        ExBanking.error_wrong_arguments() |
        ExBanking.error_user_already_exists()
    )

  def create_user(shard, user_id) do
    GenServer.call(shard, {:create_user, user_id})
  end


  @spec get_balance(
    shard :: atom(),
    user_id :: User.id(),
    currency :: Account.currency()
  ) ::
    Type.generic_return(
      ok_t :: Account.amount(),
      error_t ::
        ExBanking.error_wrong_arguments() |
        ExBanking.error_user_does_not_exist()
    )

  def get_balance(shard, user_id, currency) do
    GenServer.call(shard, {:get_balance, user_id, currency})
  end


  @spec plan_deposit(
    shard :: atom(),
    user_id :: User.id(),
    amount :: Account.amount(),
    currency :: Account.currency()
  ) ::
    Type.generic_return(
      ok_t :: Operation.operation(),
      error_t ::
        ExBanking.error_wrong_arguments() |
        ExBanking.error_user_does_not_exist() |
        ExBanking.too_many_requests_to_user()
    )

  def plan_deposit(shard, user_id, amount, currency) do
    GenServer.call(shard, {:plan_deposit, user_id, amount, currency})
  end


  @spec plan_withdraw(
    shard :: atom(),
    user_id :: User.id(),
    amount :: Account.amount(),
    currency :: Account.currency()
  ) ::
    Type.generic_return(
      ok_t :: Operation.operation(),
      error_t ::
        ExBanking.error_wrong_arguments() |
        ExBanking.error_user_does_not_exist() |
        ExBanking.error_not_enough_money() |
        ExBanking.too_many_requests_to_user()
    )

  def plan_withdraw(shard, user_id, amount, currency) do
    GenServer.call(shard, {:plan_withdraw, user_id, amount, currency})
  end


  @spec commit(
    shard :: atom(),
    user_id :: User.id(),
    currency :: Account.currency(),
    operation :: Operation.operation()
  ) ::
    Type.generic_return(
      error_t ::
        ExBanking.error_wrong_arguments() |
        ExBanking.error_user_does_not_exist() |
        Account.error_commit_failed()
    )

  def commit(shard, user_id, currency, operation) do
    GenServer.call(shard, {:commit, user_id, currency, operation})
  end


  @spec rollback(
    shard :: atom(),
    user_id :: User.id(),
    currency :: Account.currency(),
    operation :: Operation.operation()
  ) ::
    Type.generic_return(
      error_t ::
        ExBanking.error_wrong_arguments() |
        ExBanking.error_user_does_not_exist() |
        Account.error_rollback_failed()
    )

  def rollback(shard, user_id, currency, operation) do
    GenServer.call(shard, {:rollback, user_id, currency, operation})
  end


  @spec start_link(
    shard_id :: non_neg_integer()
  ) ::
    Type.ok_return(
      ok_t :: pid()
    )

  def start_link(shard_id) do
    GenServer.start_link(__MODULE__, :none, name: shard_id_to_atom(shard_id))
  end


  @spec init(
    args :: term()
  ) ::
    Type.ok_return(
      ok_t :: Map.t()
    )

  def init(_args) do
    ets = :ets.new(__MODULE__, [:protected, :set, {:keypos, 1}])
    {:ok, %{ets: ets}}
  end


  # Callbacks


  def handle_call({:create_user, user_id}, _GenReplyTo, %{ets: ets} = state) do
    if_exists_fun = fn(_user) ->
      {:error, :user_already_exists}
    end
    if_does_not_exist_fun = fn() ->
      true = :ets.insert(ets, {user_id, %User{id: user_id}})
      :ok
    end
    safe_apply(user_id, false, if_exists_fun, if_does_not_exist_fun, state)
  end

  def handle_call({:get_balance, user_id, currency}, _GenReplyTo, %{ets: _ets} = state) do
    if_exists_fun = fn(user) ->
        {:ok, integer_to_amount(User.get_balance(user, currency))}
      end
    if_does_not_exist_fun = fn() ->
      {:error, :user_does_not_exist}
    end
    safe_apply(user_id, false, if_exists_fun, if_does_not_exist_fun, state)
  end

  def handle_call({:plan_deposit, user_id, floating_point_amount, currency}, _GenReplyTo, %{ets: ets} = state) do
    if_exists_fun = fn(user) ->
      amount = amount_to_integer(floating_point_amount)
      {:ok, {operation, user}} = User.plan_deposit(user, currency, amount)
      true = :ets.insert(ets, {user.id, user})
      {:ok, operation}
    end
    if_does_not_exist_fun = fn() ->
      {:error, :user_does_not_exist}
    end
    safe_apply(user_id, true, if_exists_fun, if_does_not_exist_fun, state)
  end

  def handle_call({:plan_withdraw, user_id, floating_point_amount, currency}, _GenReplyTo, %{ets: ets} = state) do
    if_exists_fun = fn(user) ->
      amount = amount_to_integer(floating_point_amount)
      case User.plan_withdraw(user, currency, amount) do
        {:ok, {operation, user}} ->
          :ets.insert(ets, {user.id, user})
          {:ok, operation}
        {:error, reason} ->
          {:error, reason}
      end
    end
    if_does_not_exist_fun = fn() ->
      {:error, :user_does_not_exist}
    end
    safe_apply(user_id, true, if_exists_fun, if_does_not_exist_fun, state)
  end

  def handle_call({:commit, user_id, currency, operation}, _GenReplyTo, %{ets: ets} = state) do
    if_exists_fun = fn(user) ->
      case User.commit(user, currency, operation) do
        {:ok, user} ->
          :ets.insert(ets, {user.id, user})
          :ok
        {:error, reason} ->
          {:error, reason}
      end
    end
    if_does_not_exist_fun = fn() ->
      {:error, :user_does_not_exist}
    end
    safe_apply(user_id, false, if_exists_fun, if_does_not_exist_fun, state)
  end

  def handle_call({:rollback, user_id, currency, operation}, _GenReplyTo, %{ets: ets} = state) do
    if_exists_fun = fn(user) ->
      case User.rollback(user, currency, operation) do
        {:ok, user} ->
          :ets.insert(ets, {user.id, user})
          :ok
        {:error, reason} ->
          {:error, reason}
      end
    end
    if_does_not_exist_fun = fn() ->
      {:error, :user_does_not_exist}
    end
    safe_apply(user_id, false, if_exists_fun, if_does_not_exist_fun, state)
  end



  defp safe_apply(user_id, do_check_operations_count, if_exists_fun, if_does_not_exist_fun, state) do
    try do
      safe_apply_impl(user_id, do_check_operations_count, if_exists_fun, if_does_not_exist_fun, state)
    rescue
      :function_clause ->
        {:reply, {:error, :wrong_arguments}, state};
      _ ->
        {:reply, {:error, :operation_failed}, state}
    end
  end


  defp safe_apply_impl(user_id, do_check_operations_count, if_exists_fun, if_does_not_exist_fun, %{ets: ets} = state) do
    case :ets.lookup(ets, user_id) do
      [] ->
        {:reply, if_does_not_exist_fun.(), state};
      [{_user_id, user}] ->
        case {User.get_operations_count(user), do_check_operations_count} do
          {too_much, true} when too_much >= 10 ->
            {:reply, {:error, :too_many_requests_to_user}, state};
          {_n, _} ->
            {:reply, if_exists_fun.(user), state}
        end
    end
  end


  defp amount_to_integer(floating_point_amount) do
    :erlang.floor(floating_point_amount * 100)
  end


  defp integer_to_amount(amount) do
    amount / 100
  end

end

