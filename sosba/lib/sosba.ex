require Amnesia
require Database

use Amnesia
use Database

defmodule Sosba do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Periodically, [])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Sosba.Supervisor]
    svReturn = Supervisor.start_link(children, opts)

    #init database
    Amnesia.start
    Database.create(ram: [node])
    Database.wait
    Amnesia.transaction do: User.create("hans", "a", "bbb")
    
    #start expects us to return this value
    svReturn
  end
end
