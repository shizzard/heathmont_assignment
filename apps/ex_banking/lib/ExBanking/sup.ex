defmodule ExBanking.Supervisor do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, :none, name: __MODULE__)
  end

  def init(_arg) do
    children = [
      Supervisor.child_spec(ExBanking.Shard, start: {ExBanking.Shard, :start_link, []})
    ]
    Supervisor.init(children, strategy: :simple_one_for_one)
  end
end
