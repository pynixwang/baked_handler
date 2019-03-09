require "ecr/macros"
require "html"
require "uri"
require "baked_file_system"

class HTTP::BakedHandler(T)
  include HTTP::Handler

  def initialize(fallthrough = true)
    @fallthrough = !!fallthrough
  end

  def call(context)
    unless context.request.method == "GET" || context.request.method == "HEAD"
      if @fallthrough
        call_next(context)
      else
        context.response.status_code = 405
        context.response.headers.add("Allow", "GET, HEAD")
      end
      return
    end

    original_path = context.request.path.not_nil!
    request_path = self.request_path(URI.unescape(original_path))

    # File path cannot contains '\0' (NUL) because all filesystem I know
    # don't accept '\0' character as file name.
    if request_path.includes? '\0'
      context.response.status_code = 400
      return
    end

    file_path = File.expand_path(request_path, "/")

    if file = T.get?(file_path)
      context.response.content_type = mime_type(file_path)
      context.response.content_length = file.size
      IO.copy(file, context.response)
    else
      call_next(context)
    end
  end

  # given a full path of the request, returns the path
  # of the file that should be expanded at the public_dir
  protected def request_path(path : String) : String
    path
  end

  private def mime_type(path)
    case File.extname(path)
    when ".txt"          then "text/plain"
    when ".htm", ".html" then "text/html"
    when ".css"          then "text/css"
    when ".js"           then "application/javascript"
    else                      "application/octet-stream"
    end
  end

end
