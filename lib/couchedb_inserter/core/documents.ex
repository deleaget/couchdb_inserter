defmodule CouchdbInserter.Documents do
  require Logger

  @chunk_size 2

  def insert_new_docs(payload_request) do
    [server: server, username: username, password: password, port: port, db_name: db_name] = Application.get_env(:couchdb_inserter, :database)
    url = "http://#{username}:#{password}@#{server}:#{port}/#{db_name}/_bulk_docs"

    cond do
      is_map(payload_request["doc"]) || is_list(payload_request["docs"]) ->
        docs = List.wrap(payload_request["doc"] || payload_request["docs"])
        full_resp = %{valid_responses: valid_responses, error_responses: error_responses} = CouchdbInserter.Documents.process_bulk_docs(url, docs)

        status_code =
          cond do
            Enum.count(error_responses) == 0 ->
              200

            Enum.count(valid_responses) == 0 ->
              error_responses
              |> List.first()
              |> Map.get(:status_code)

            true ->
              206
          end

        %{status_code: status_code, response: full_resp}

      true ->
        Logger.error("[#{__MODULE__}] 400 Bad Request")
        %{status_code: 400, response: %{reason: "Bad Request - API Need JSON objects like docs: <list> or doc: <object>"}}
    end
  end


  def process_bulk_docs(url, docs) do
    docs
    |> Stream.chunk_every(@chunk_size)
    |> Task.async_stream(fn chunk_docs ->
      body = %{docs: chunk_docs}
      CouchdbInserter.Http.Client.post(url, Poison.encode!(body))
    end, max_concurrency: 8, timeout: 10_0000)
    |> Stream.map(fn {:ok, resp} -> resp end)
    |> Enum.reduce(%{valid_responses: [], error_responses: []}, fn post_response, %{valid_responses: valid_responses, error_responses: error_responses} ->
      case post_response do

        # Valid response, 201 = Items created successfully
        {:ok, {{_, 201, _}, _, resp}} ->
          updated_valid_responses =
            valid_responses
            |> Enum.concat([Poison.decode!(resp)])
          %{valid_responses: updated_valid_responses, error_responses: error_responses}

        # Valid response Http, but an error has occurred
        {:ok, {{_, status_code, _}, _, resp}} ->
          updated_error_responses =
            error_responses
            |> Enum.concat([
              %{status_code: status_code, reason: resp}
            ])
          %{valid_responses: valid_responses, error_responses: updated_error_responses}

        # Other error, like timeout or failed_connect
        error ->
          updated_error_responses =
            error_responses
            |> Enum.concat([
              %{status_code: 500, reason: "Unknow error : #{inspect(error)}"}
            ])
          %{valid_responses: valid_responses, error_responses: updated_error_responses}
      end
    end)
  end

end
