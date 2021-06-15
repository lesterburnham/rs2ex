defmodule Rs2ex.Server do
  require Logger

  @port 43594

  def start_link(_args) do
    Logger.debug("[tcp] starting server on port :#{@port}")
    {:ok, _} = :ranch.start_listener(make_ref(), :ranch_tcp, [{:port, @port}], Rs2ex.Handler, [])
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
