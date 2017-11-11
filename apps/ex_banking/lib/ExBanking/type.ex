defmodule ExBanking.Type do
  @moduledoc """
    Application-wide types container
  """

  @typedoc """
    Generic `ok` return type.
  """
  @type ok_return() :: :ok

  @typedoc """
    Generic `{ok, Return}` return type.
  """
  @type ok_return(ret_t) :: {:ok, ret_t}

  @typedoc """
    Generic `{ok, Return1, Return2}` return type.
  """
  @type ok_return(ret_t1, ret_t2) :: {:ok, ret_t1, ret_t2}

  @typedoc """
    Generic `{error, Reason}` return type.
  """
  @type error_return(err_t) :: {:error, err_t}

  @typedoc """
    Generic `ok | {error, Reason}` return type.
  """
  @type generic_return(err_t) ::
    ok_return() |
    error_return(err_t)

  @typedoc """
    Generic `{ok, Return} | {error, Reason}` return type.
  """
  @type generic_return(ret_t, err_t) ::
    ok_return(ret_t) |
    error_return(err_t)

  @typedoc """
    Generic `{ok, Return1, Return2} | {error, Reason}` return type.
  """
  @type generic_return(ret_t1, ret_t2, err_t) ::
    ok_return(ret_t1, ret_t2) |
    error_return(err_t)
end
