#!/usr/local/bin/ruby 
require 'open3'
require 'json'
require './tcpserver'
require './configio'
require './logger/logger.rb'
require './HttpRequest/HttpRequest.rb'
class HttpServer
    attr_accessor :host
    attr_accessor :port
    attr_accessor :cgi_bin_path
    attr_accessor :config_file
    cgi_bin_path="cgi_bin"
    config_file="default.yml"
    def process(req)
        @log.debug(req)
        request=HttpRequest.new(req)
        @log.info("\n\tcalled:\t"+request.path.to_s+"\n\twith arguments:\t"+request.query.to_json.to_s)
        # invoke the script in cgi_bin_path
        # pass in the parameters as a hashtable
        # return the results of the script
        stdin,stdout,stderr,wait_thr=Open3.popen3("#{cgi_bin_path}#{request.path}")
        stdin.write request.query.to_json
        stdin.close 
        wait_thr.join
        response=stdout.read
        error=stderr.read
        stdout.close
        stderr.close
        if error!=""
            @log.error("Script error:\n"+error.to_s)
            return error
        else
            return response
        end
        # passing parameters as a hastable makes 
        # no sense, but it is what the specs say 
        #to do.
    end

    def start
        # does this actualy serve a purpouse?
        # the specs never say that anything 
        # should be done with the tcp server
        # only that TCPServ should call HTTPServ
        # and then have the results returned.
        tcp = TcpServer.new( self , @config)
        tcp.start
    end
    def initialize
        # is it really this simple?
        # it seems like it shouldnt be but is.
        @log=Logger.instance
        @log.info("HTTPServ starting")
        @config=ConfigIO.instance
        config_file="config.yml"
        @config.read(config_file)
        @log.info("Config file \""+config_file+"\" read")
        cgi_bin_path=@config.config[cgi_bin_path]
        host=@config.config[host]
        port=@config.config[port]
        yield self
        @log.info("HTTPServ started")
    end
end

server = HttpServer.new { |s|
  s.host = "localhost"
  s.port = 8000
  s.cgi_bin_path = "cgi_bin"
}

server.start

