defmodule ExBanking do
  require Logger
  alias ExBanking.Type
  alias ExBanking.Account
  alias ExBanking.User

  @moduledoc """
    ExBanking interface module as stated in https://github.com/heathmont/elixir-test
  """

  @type error_wrong_arguments() :: :wrong_arguments
  @type error_user_already_exists() :: :user_already_exists
  @type error_user_does_not_exist() :: :user_does_not_exist
  @type error_not_enough_money() :: :not_enough_money
  @type error_sender_does_not_exist() :: :sender_does_not_exist
  @type error_receiver_does_not_exist() :: :receiver_does_not_exist
  @type error_too_many_requests_to_user() :: :too_many_requests_to_user
  @type error_too_many_requests_to_sender() :: :too_many_requests_to_sender
  @type error_too_many_requests_to_receiver() :: :too_many_requests_to_receiver

  @typedoc """
    Banking error reasons.
  """
  @type error() ::
    error_wrong_arguments() |
    error_user_already_exists() |
    error_user_does_not_exist() |
    error_not_enough_money() |
    error_sender_does_not_exist() |
    error_receiver_does_not_exist() |
    error_too_many_requests_to_user() |
    error_too_many_requests_to_sender() |
    error_too_many_requests_to_receiver()


  @spec get_shard_by_user_id(
    user_id :: User.id()
  ) ::
    ret :: atom()

  def get_shard_by_user_id(user_id) do
    shards_count = Application.get_env(:ex_banking, :shards_count)
    shard_id = rem(:erlang.crc32(:erlang.term_to_binary(user_id)), shards_count) + 1
    ExBanking.Shard.shard_id_to_atom(shard_id)
  end


  @doc """
    Function creates new user in the system
    New user has zero balance of any currency
  """
  @spec create_user(
    user :: User.id()
  ) ::
    Type.generic_return(
      err_t :: error()
    )

  def create_user(user) do
    shard = get_shard_by_user_id(user)
    ExBanking.Shard.create_user(shard, user)
  end


  @doc """
    Increases user's balance in given currency by amount value
    Returns new_balance of the user in given format
  """
  @spec deposit(
    user :: User.id(),
    amount :: Account.amount(),
    currency :: Account.currency()
  ) ::
    Type.generic_return(
      ok_t :: Account.amount(),
      err_t :: error()
    )

  def deposit(user, amount, currency) do
    shard = get_shard_by_user_id(user)
    case ExBanking.Shard.plan_deposit(shard, user, amount, currency) do
        {:ok, operation} ->
            :ok = ExBanking.Shard.commit(shard, user, currency, operation)
            {:ok, amount} = ExBanking.Shard.get_balance(shard, user, currency)
            {:ok, amount}
        {:error, reason} ->
            {:error, reason}
    end
  end


  @doc """
    Decreases user's balance in given currency by amount value
    Returns new_balance of the user in given format
  """
  @spec withdraw(
    user :: User.id(),
    amount :: Account.amount(),
    currency :: Account.currency()
  ) ::
    Type.generic_return(
      ok_t :: Account.amount(),
      err_t :: error()
    )

  def withdraw(user, amount, currency) do
    shard = get_shard_by_user_id(user)
    case ExBanking.Shard.plan_withdraw(shard, user, amount, currency) do
        {:ok, operation} ->
            :ok = ExBanking.Shard.commit(shard, user, currency, operation)
            {:ok, amount} = ExBanking.Shard.get_balance(shard, user, currency)
            {:ok, amount}
        {:error, reason} ->
            {:error, reason}
    end
  end


  @doc """
    Returns balance of the user in given format
  """
  @spec get_balance(
    user :: User.id(),
    currency :: Account.currency()
  ) ::
    Type.generic_return(
      ok_t :: Account.amount(),
      err_t :: error()
    )

  def get_balance(user, currency) do
    shard = get_shard_by_user_id(user)
    ExBanking.Shard.get_balance(shard, user, currency)
  end


  @doc """
    Decreases from_user's balance in given currency by amount value
    Increases to_user's balance in given currency by amount value
    Returns balance of from_user and to_user in given format
  """
  @spec send(
    from_user :: User.id(),
    to_user :: User.id(),
    amount :: Account.amount(),
    currency :: Account.currency()
  ) ::
    Type.generic_return(
      ok_t1 :: Account.amount(),
      ok_t2 :: Account.amount(),
      err_t :: error()
    )

  def send(from, to, amount, currency) do
    do_send_steps(from, to, amount, currency)
  end



  def do_send_steps(from, to, amount, currency) do
    from_shard = get_shard_by_user_id(from)
    to_shard = get_shard_by_user_id(to)
    do_send_step_1_withdraw(from_shard, from, to_shard, to, amount, currency)
  end


  def do_send_step_1_withdraw(from_shard, from, to_shard, to, amount, currency) do
    case ExBanking.Shard.plan_withdraw(from_shard, from, amount, currency) do
        {:ok, from_operation} ->
            do_send_step_2_deposit(from_shard, from, from_operation, to_shard, to, amount, currency);
        {:error, :user_does_not_exist} ->
            {:error, :sender_does_not_exist};
        {:error, :too_many_requests_to_user} ->
            {:error, :too_many_requests_to_sender};
        {:error, reason} ->
            {:error, reason}
    end
  end


  def do_send_step_2_deposit(from_shard, from, from_operation, to_shard, to, amount, currency) do
    case ExBanking.Shard.plan_deposit(to_shard, to, amount, currency) do
        {:ok, to_operation} ->
            do_send_step_3_commit(
                from_shard, from, from_operation, to_shard, to, to_operation, amount, currency);
        {:error, :user_does_not_exist} ->
            do_send_step_3_rollback(
                from_shard, from, from_operation, to_shard, to, :receiver_does_not_exist, amount, currency);
        {:error, :too_many_requests_to_user} ->
            do_send_step_3_rollback(
                from_shard, from, from_operation, to_shard, to, :too_many_requests_to_receiver, amount, currency);
        {:error, reason} ->
            do_send_step_3_rollback(
                from_shard, from, from_operation, to_shard, to, reason, amount, currency)
    end
  end


  def do_send_step_3_commit(from_shard, from, from_operation, to_shard, to, to_operation, _amount, currency) do
    try do
        :ok = ExBanking.Shard.commit(from_shard, from, currency, from_operation)
        :ok = ExBanking.Shard.commit(to_shard, to, currency, to_operation)
        do_send_step_4_amounts(from_shard, from, to_shard, to, currency)
    rescue
        _ -> {:error, :operation_failed}
    end
  end


  def do_send_step_3_rollback(from_shard, from, from_operation, _to_shard, _to, reason, _amount, currency) do
    try do
        :ok = ExBanking.Shard.rollback(from_shard, from, currency, from_operation)
        {:error, reason}
    rescue
        _ -> {:error, :operation_failed}
    end
  end


  def do_send_step_4_amounts(from_shard, from, to_shard, to, currency) do
    {:ok, from_amount} = ExBanking.Shard.get_balance(from_shard, from, currency)
    {:ok, to_amount} = ExBanking.Shard.get_balance(to_shard, to, currency)
    {:ok, from_amount, to_amount}
  end

end
