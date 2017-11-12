defmodule ExBanking.Application do
  @moduledoc false

  use Application
  require Logger

  def start(_type, _args) do
    Logger.info fn -> "Starting app" end
    ret = ExBanking.Supervisor.start_link()
    for shard_id <- :lists.seq(1, Application.get_env(:ex_banking, :shards_count)) do
      Supervisor.start_child(ExBanking.Supervisor, [shard_id])
    end
    ret
  end
end
