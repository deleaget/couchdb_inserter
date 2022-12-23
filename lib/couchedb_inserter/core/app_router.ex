defmodule CouchdbInserter.Router do
  use Plug.Router
  use CouchdbInserter.Http.Wrapper

  require Logger

  plug(Plug.Logger)
  plug(:fetch_query_params)
  plug(:match)
  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Poison
  )
  plug(:dispatch)

  @list_of_apis [
    %{
      path: "/insert",
      method: "POST",
      name: "Insert document API",
      body_example: %{
        example_1: %{
          doc: %{name: "My first document", info: "This is an example"}
        },
        example_2: %{
          docs: [
            %{name: "My first document", info: "This is an example"},
            %{name: "Banana", protein: 1.1},
          ]
        },
      }
    }
  ]


  get "/" do
    conn
    |> wrapper_send_resp(200, @list_of_apis)
  end

  post "/insert" do
    payload_request =
      conn
      |> fetch_query_params()
      |> Map.get(:body_params, Map.new())

    Logger.debug(["[#{__MODULE__}] \n> Payload request \n#{inspect(payload_request)}"])

    %{status_code: status_code, response: resp} = CouchdbInserter.Documents.insert_new_docs(payload_request)

    conn
    |> wrapper_send_resp(status_code, resp)
  end

  match _ do
    conn
    |> wrapper_send_resp(404, %{})
  end
end
