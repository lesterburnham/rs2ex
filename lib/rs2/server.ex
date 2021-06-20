defmodule RS2.Server do
  require Logger

  @port 43_594

  def start_link(_args) do
    Logger.debug("[tcp] starting server on port :#{@port}")
    {:ok, _} = :ranch.start_listener(make_ref(), :ranch_tcp, [{:port, @port}], RS2.Handler, [])
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end
end
