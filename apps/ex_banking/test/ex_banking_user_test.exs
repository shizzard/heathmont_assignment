defmodule ExBankingUserTest do
  use ExUnit.Case
  alias ExBanking.Account
  alias ExBanking.User
  doctest ExBanking.User


  test "can get zero balance by new currency test" do
    user = %User{id: "Mike"}
    assert(0 == User.get_balance(user, "USD"))
  end


  test "can get error getting balance by invalid currency test" do
    user = %User{id: "Mike"}
    catch_error(User.get_balance(user, :USD))
  end


  test "can run deposit operation test" do
    user = %User{id: "Mike"}
    {:ok, {_operation, user}} = User.plan_deposit(user, "USD", 100)
    assert(0 == User.get_balance(user, "USD"))
    assert(1 == User.get_operations_count(user, "USD"))
  end

  test "can commit deposit operation test" do
    user = %User{id: "Mike"}
    {:ok, {operation, user}} = User.plan_deposit(user, "USD", 100)
    {:ok, user} = User.commit(user, "USD", operation)
    assert(100 == User.get_balance(user, "USD"))
    assert(0 == User.get_operations_count(user, "USD"))
  end

  test "can run withdraw operation test" do
    user = %User{id: "Mike"}
    {:ok, {operation, user}} = User.plan_deposit(user, "USD", 100)
    {:ok, user} = User.commit(user, "USD", operation)
    {:ok, {_operation, user}} = User.plan_withdraw(user, "USD", 50)
    assert(50 == User.get_balance(user, "USD"))
    assert(1 == User.get_operations_count(user, "USD"))
  end

  test "can commit withdraw operation test" do
    user = %User{id: "Mike"}
    {:ok, {operation, user}} = User.plan_deposit(user, "USD", 100)
    {:ok, user} = User.commit(user, "USD", operation)
    assert(100 == User.get_balance(user, "USD"))
    {:ok, {operation, user}} = User.plan_withdraw(user, "USD", 50)
    {:ok, user} = User.commit(user, "USD", operation)
    assert(50 == User.get_balance(user, "USD"))
    assert(0 == User.get_operations_count(user, "USD"))
  end
end
