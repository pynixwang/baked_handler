```
require "http/server"
require "./baked_handler"
require "baked_file_system"

class StaticBaked
  extend BakedFileSystem
  bake_folder "../public"
end


server = HTTP::Server.new([
  HTTP::ErrorHandler.new,
  HTTP::LogHandler.new,
  HTTP::CompressHandler.new,
  HTTP::BakedHandler(StaticBaked).new,
])

server.bind_tcp "127.0.0.1", 8080
server.listen
```