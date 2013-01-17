module Selbot2
  class Revisions
    include Cinch::Plugin

    HELPS << ["<git sha>", "show revision"]

    listen_to :message

    def listen(m)
      RevisionFinder.each(m.message) do |resp|
        m.reply(resp)
      end
    end
  end

  module RevisionFinder
    RX = /\b([a-f\d]{5,40}|HEAD)\b/

    module_function

    def git
      @git ||= Git.new
    end

    def each(str)
      shas = str.scan(RX).flatten

      result = []

      shas.each do |sha|
        reply = find(sha)
        if reply
          yield reply if block_given?
          result << reply
        end
      end

      result
    end

    def find(sha)
      obj = git.commit(sha)

      if obj
        Util.format_revision obj.author[:name],
                             Time.at(obj.time).utc,
                             obj.message.strip,
                             obj.oid[0,7]
      end
    rescue => ex
      p [ex.message, ex.backtrace.first]
      nil
    end
  end
end
