defmodule CouchdbInserter.Http.Wrapper do

  defmacro __using__(_opts) do
    quote do
      def wrapper_send_resp(conn, status_code, response, type \\ "application/json") do
        conn
        |> put_resp_content_type(type)
        |> send_resp(status_code, Poison.encode!(response))
      end
    end
  end

end

defmodule CouchdbInserter.Http.Client do
  require Logger

  def post(url, body, type \\ 'application/json', opts \\ [timeout: 10_000]) do
    Logger.debug("[#{__MODULE__}] POST at #{url}")
    :httpc.request(:post, {url, [], type, body}, opts, [])
  end
end
