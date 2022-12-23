[
  couchdb_inserter: [
    database: [
      server: "127.0.0.1",
      username: "admin",
      password: "password",
      port: 5984,
      db_name: "cosy-cloud"
    ]
  ],
  logger: [
    level: :debug,
    truncate: :infinity
  ]
]
