defmodule PentoWeb.Plugs.SessionManager do
  @moduledoc """
  Plug to manage game session IDs across requests
  """
  
  import Plug.Conn
  
  def init(opts), do: opts
  
  def call(conn, _opts) do
    session_id = get_session(conn, :session_id) || Ecto.UUID.generate()
    put_session(conn, :session_id, session_id)
  end
end