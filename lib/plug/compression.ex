defmodule Plug.Compression do
  import Plug.Conn

  @supported [:gzip, :deflate]
  @content_encoding "content-encoding"

  def init([]), do: @supported
  def init(only: algorithm) when is_atom(algorithm) and algorithm in @supported, do: [algorithm]
  def init(only: algorithm) when is_atom(algorithm), do: raise ArgumentError, "invalid compression: #{inspect(algorithm)}"

  def init(only: algorithms) when is_list(algorithms) do
    invalid = algorithms -- @supported

    if invalid != [] do
      raise ArgumentError, message: "invalid compression: #{inspect(invalid)}"
    else
      algorithms
    end
  end

  def init(opts), do: raise ArgumentError, message: "invalid opts: #{inspect(opts)}"

  def call(conn, algoritms) do
    case get_compression(conn, algoritms) do
      nil -> conn
      :gzip -> Plug.Conn.register_before_send(conn, &gzip/1)
      :deflate -> Plug.Conn.register_before_send(conn, &deflate/1)
    end
  end

  defp gzip(conn) do
    conn
    |> put_resp_header(@content_encoding, "gzip")
    |> Map.update!(:resp_body, &:zlib.gzip/1)
  end

  defp deflate(conn) do
    conn
    |> put_resp_header(@content_encoding, "deflate")
    |> Map.update!(:resp_body, &do_deflate/1)
  end

  defp do_deflate(body) do
    stream = :zlib.open()
    :ok = :zlib.deflateInit(stream)
    deflated = :zlib.deflate(stream, body, :finish)
    :zlib.deflateEnd(stream)
    :zlib.close(stream)

    deflated
  end

  defp get_compression(conn, values) do
    values = values |> Enum.map(&Atom.to_string/1)

    conn
    |> Plug.Conn.get_req_header("accept-encoding")
    |> Enum.flat_map(&Plug.Conn.Utils.list/1)
    |> Enum.filter(&(String.downcase(&1, :ascii) in values))
    |> List.first()
    |> case do
      nil -> nil
      val -> String.to_existing_atom(val)
    end
  end
end
