defmodule ExBanking.Operation do
  @moduledoc """
    An abstraction of operation in the system. Every operation is unique
    and contains operation `type` (`deposit | withdraw`) and amount.
    Every `ExBanking.Account` mutation is to be performed with `ExBanking.Operation`.
  """
  alias ExBanking.Account

  @type id() :: any()
  @type type_deposit() :: :deposit
  @type type_withdraw() :: :withdraw
  @type type() :: type_deposit() | type_withdraw()

  @type t() :: %__MODULE__{
    id: id(),
    type: type(),
    amount: Account.amount()
  }
  defstruct [:id, :type, amount: 0]
end
