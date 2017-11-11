defmodule ExBanking do
  @moduledoc """
    ExBanking interface module as stated in https://github.com/heathmont/elixir-test
  """

  @typedoc """
    Banking error reasons.
  """
  @type banking_error_reason ::
    :wrong_arguments                |
    :user_already_exists            |
    :user_does_not_exist            |
    :not_enough_money               |
    :sender_does_not_exist          |
    :receiver_does_not_exist        |
    :too_many_requests_to_user      |
    :too_many_requests_to_sender    |
    :too_many_requests_to_receiver

  @doc """
    Function creates new user in the system
    New user has zero balance of any currency
  """
  @spec create_user(user :: String.t) ::
    ExBanking.Type.generic_return(err_t :: banking_error_reason)
  def create_user(_user) do
    :ok
  end

  @doc """
    Increases user's balance in given currency by amount value
    Returns new_balance of the user in given format
  """
  @spec deposit(user :: String.t, amount :: number, currency :: String.t) ::
    ExBanking.Type.generic_return(new_balance :: number, err_t :: banking_error_reason)
  def deposit(_user, _amount, _currency) do
    {:ok, 0}
  end

  @doc """
    Decreases user's balance in given currency by amount value
    Returns new_balance of the user in given format
  """
  @spec withdraw(user :: String.t, amount :: number, currency :: String.t) ::
    ExBanking.Type.generic_return(new_balance :: number, err_t :: banking_error_reason)
  def withdraw(_user, _amount, _currency) do
    {:ok, 0}
  end

  @doc """
    Returns balance of the user in given format
  """
  @spec get_balance(user :: String.t, currency :: String.t) ::
    ExBanking.Type.generic_return(balance :: number, err_t :: banking_error_reason)
  def get_balance(_user, _currency) do
    {:ok, 0}
  end

  @doc """
    Decreases from_user's balance in given currency by amount value
    Increases to_user's balance in given currency by amount value
    Returns balance of from_user and to_user in given format
  """
  @spec send(from_user :: String.t, to_user :: String.t, amount :: number, currency :: String.t) ::
    ExBanking.Type.generic_return(from_user_balance :: number, to_user_balance :: number, err_t :: banking_error_reason)
  def send(_from, _to, _amount, _currency) do
    {:ok, 0, 0}
  end

end
