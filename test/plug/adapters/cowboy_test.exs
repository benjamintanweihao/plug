defmodule Plug.Adapters.CowboyTest do
  use ExUnit.Case, async: true

  import Plug.Adapters.Cowboy

  def init([]) do
    [foo: :bar]
  end

  @dispatch [{:_, [], [
              {:_, [], Plug.Adapters.Cowboy.Handler, {Plug.Adapters.CowboyTest, [foo: :bar]}}
            ]}]

  test "builds args for cowboy dispatch" do
    assert args(:http, __MODULE__, [], []) ==
           [Plug.Adapters.CowboyTest.HTTP,
            100,
            [port: 4000],
            [env: [dispatch: @dispatch]]]
  end

  test "builds args with custom options" do
    assert args(:http, __MODULE__, [], [port: 3000, acceptors: 25, other: true]) ==
           [Plug.Adapters.CowboyTest.HTTP,
            25,
            [port: 3000, other: true],
            [env: [dispatch: @dispatch]]]
  end

  test "builds args with protocol option" do
    assert args(:http, __MODULE__, [], [port: 3000, acceptors: 25, compress: true, timeout: 30000]) ==
           [Plug.Adapters.CowboyTest.HTTP,
            25,
            [port: 3000],
            [env: [dispatch: @dispatch], compress: true, timeout: 30000]]

    assert args(:http, __MODULE__, [], [port: 3000, acceptors: 25, protocol_options: [timeout: 30000]]) ==
           [Plug.Adapters.CowboyTest.HTTP,
            25,
            [port: 3000],
            [env: [dispatch: @dispatch], timeout: 30000]]
  end

  test "builds child specs" do
    args = [Plug.Adapters.CowboyTest.HTTP,
            100,
            :ranch_tcp,
            [port: 4000],
            :cowboy_protocol,
            [env: [dispatch: @dispatch]]]

    assert child_spec(:http, __MODULE__, [], []) ==
           {{:ranch_listener_sup, Plug.Adapters.CowboyTest.HTTP},
            {:ranch_listener_sup, :start_link, args},
            :permanent,
            :infinity,
            :supervisor,
            [:ranch_listener_sup]}
  end

  defmodule MyPlug do
    def init(opts), do: opts
  end

  test "errors when trying to run on https" do
    assert_raise ArgumentError, ~r/missing option :key\/:keyfile/, fn ->
      Plug.Adapters.Cowboy.https MyPlug, [], []
    end

    assert_raise ArgumentError, ~r/ssl\/key\.pem required by SSL's :keyfile does not exist/, fn ->
      Plug.Adapters.Cowboy.https MyPlug, [],
        keyfile: "priv/ssl/key.pem",
        certfile: "priv/ssl/cert.pem",
        otp_app: :plug
    end
  end
end
