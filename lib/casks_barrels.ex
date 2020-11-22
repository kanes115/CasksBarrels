defmodule CasksBarrels do
  use Application

  def start(_type, _args) do
    children = [
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: CasksBarrelsWeb.Router,
        options: [
          dispatch: dispatch(),
          port: 4000
        ]
      ),
      CasksBarrels.RoomManager
    ]

    opts = [strategy: :one_for_one, name: CasksBarrels]
    Supervisor.start_link(children, opts)
  end

  defp dispatch do
    [
      {:_,
       [
         {"/ws/[...]", CasksBarrelsWeb.SocketHandler, []}
       ]}
    ]
  end
end
