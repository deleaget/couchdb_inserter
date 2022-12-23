defmodule CouchdbInserter.Documents do
  require Logger


  def insert_new_docs(payload_request) do
    [server: server, username: username, password: password, port: port, db_name: db_name] = Application.get_env(:couchdb_inserter, :database)
    url = "http://#{username}:#{password}@#{server}:#{port}/#{db_name}/_bulk_docs"

    body_formatted =
      cond do
        is_map(payload_request["doc"]) || is_list(payload_request["docs"]) ->
          {:ok, %{docs: List.wrap(payload_request["doc"] || payload_request["docs"])}}

        true ->
          Logger.error("[#{__MODULE__}] 400 Bad Request")
          %{status_code: 400, response: %{reason: "Bad Request - API Need JSON objects like docs: <list> or doc: <object>"}}
      end

    with {:ok, body} <- body_formatted,
         {:ok, {{_, 201, _}, _, resp}} <- CouchdbInserter.Http.Client.post(url, Poison.encode!(body)) do
          %{status_code: 201, response: Poison.decode!(resp)}
    else
      {:ok, {{_, status_code, _}, _, resp}} ->
        %{status_code: status_code, response: resp}

      error ->
        error
    end
  end

end
