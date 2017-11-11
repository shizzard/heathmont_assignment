defmodule ExBankingAccountTest do
  use ExUnit.Case
  alias ExBanking.Account
  alias ExBanking.Operation
  doctest ExBanking.Account


  test "can plan deposit operation" do
    account = %Account{currency: "USD"}
    {:ok, {operation, account}} = Account.plan_deposit(account, 100)
    assert(0 == account.amount)
    assert(1 == Account.operations_count(account))
    assert(100 == operation.amount)
    assert(:deposit == operation.type)
  end

  test "can error on invalid deposit operation amount" do
    account = %Account{currency: "USD"}
    catch_error(Account.plan_deposit(account, -1))
    catch_error(Account.plan_deposit(account, 1.11))
  end


  test "can rollback deposit operation" do
    account = %Account{currency: "USD"}
    {:ok, {operation, account}} = Account.plan_deposit(account, 100)
    {:ok, account} = Account.rollback(account, operation)
    assert(0 == account.amount)
    assert(0 == Account.operations_count(account))
  end


  test "can plan withdraw operation" do
    account = %Account{currency: "USD", amount: 100}
    {:ok, {operation, account}} = Account.plan_withdraw(account, 100)
    assert(0 == account.amount)
    assert(1 == Account.operations_count(account))
    assert(100 == operation.amount)
    assert(:withdraw == operation.type)
  end


  test "can error on invalid withdraw operation amount" do
    account = %Account{currency: "USD"}
    catch_error(Account.plan_withdraw(account, -1))
    catch_error(Account.plan_withdraw(account, 1.11))
  end


  test "can error on withdraw operation with insufficient funds" do
    account = %Account{currency: "USD"}
    assert({:error, :not_enough_money} == Account.plan_withdraw(account, 1))
  end


  test "can commit withdraw operation" do
    account = %Account{currency: "USD", amount: 100}
    {:ok, {operation, account}} = Account.plan_withdraw(account, 100)
    {:ok, account} = Account.commit(account, operation)
    assert(0 == account.amount)
    assert(0 == Account.operations_count(account))
  end


  test "can rollback withdraw operation" do
    account = %Account{currency: "USD", amount: 100}
    {:ok, {operation, account}} = Account.plan_withdraw(account, 100)
    {:ok, account} = Account.rollback(account, operation)
    assert(100 == account.amount)
    assert(0 == Account.operations_count(account))
  end


  test "can error on invalid operation commit" do
    account = %Account{currency: "USD"}
    {:ok, {_Operation, account}} = Account.plan_deposit(account, 100)
    invalid_operation = %Operation{id: make_ref(), type: :deposit, amount: 100}
    assert({:error, :commit_failed} == Account.commit(account, invalid_operation))
  end


  test "can error on invalid operation rollback" do
    account = %Account{currency: "USD"}
    {:ok, {_Operation, account}} = Account.plan_deposit(account, 100)
    invalid_operation = %Operation{id: make_ref(), type: :deposit, amount: 100}
    assert({:error, :rollback_failed} == Account.rollback(account, invalid_operation))
  end

end
