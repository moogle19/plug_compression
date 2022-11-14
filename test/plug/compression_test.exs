defmodule Plug.CompressionTest do
  use ExUnit.Case, async: true
  use Plug.Test

  import Plug.Conn

  @opts Plug.Compression.init([])

  test "valid compression algortihm" do
    assert Plug.Compression.init(only: :gzip) == [:gzip]
    assert Plug.Compression.init(only: :deflate) == [:deflate]
    assert Plug.Compression.init(only: [:gzip]) == [:gzip]
    assert Plug.Compression.init(only: [:gzip, :deflate]) == [:gzip, :deflate]
  end

  test "unsupported compression algorithm" do
    assert_raise ArgumentError, "invalid compression: [:brotli]", fn ->
      Plug.Compression.init(only: [:brotli])
    end

    assert_raise ArgumentError, "invalid compression: :brotli", fn ->
      Plug.Compression.init(only: :brotli)
    end
  end

  test "invalid opts" do
    assert_raise ArgumentError, "invalid opts: [compression: :gzip]", fn ->
      Plug.Compression.init(compression: :gzip)
    end
  end

  test "no accept-encoding header" do
    conn = conn(:get, "/test")

    conn =
      conn
      |> Plug.Compression.call(@opts)
      |> Plug.Conn.send_resp(200, "foo")

    assert conn.status == 200
    assert conn.resp_body == "foo"
  end

  test "gzip compression" do
    conn = conn(:get, "/test") |> put_req_header("accept-encoding", "gzip")

    conn =
      conn
      |> Plug.Compression.call(@opts)
      |> Plug.Conn.send_resp(200, "foo")

    assert conn.status == 200
    assert get_resp_header(conn, "content-encoding") == ["gzip"]
    assert Base.encode64(conn.resp_body) == "H4sIAAAAAAAAE0vLzwcAIWVzjAMAAAA="
  end

  test "deflate compression" do
    conn = conn(:get, "/test") |> put_req_header("accept-encoding", "deflate")

    conn =
      conn
      |> Plug.Compression.call(@opts)
      |> Plug.Conn.send_resp(200, "foo")

    assert conn.status == 200
    assert get_resp_header(conn, "content-encoding") == ["deflate"]
    assert Base.encode64(conn.resp_body) == "eJxLy88HAAKCAUU="
  end

  test "encoding priority gzip" do
    conn = conn(:get, "/test") |> put_req_header("accept-encoding", "gzip,deflate")

    conn =
      conn
      |> Plug.Compression.call(@opts)
      |> Plug.Conn.send_resp(200, "foo")

    assert conn.status == 200
    assert get_resp_header(conn, "content-encoding") == ["gzip"]
    assert Base.encode64(conn.resp_body) == "H4sIAAAAAAAAE0vLzwcAIWVzjAMAAAA="
  end

  test "encoding priority deflate" do
    conn = conn(:get, "/test") |> put_req_header("accept-encoding", "deflate,gzip")

    conn =
      conn
      |> Plug.Compression.call(@opts)
      |> Plug.Conn.send_resp(200, "foo")

    assert conn.status == 200
    assert get_resp_header(conn, "content-encoding") == ["deflate"]
    assert Base.encode64(conn.resp_body) == "eJxLy88HAAKCAUU="
  end
end
