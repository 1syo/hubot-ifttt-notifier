# Description
#   A hubot script that does the things
#
# Notes:
#   <optional notes required for the script>
#
# Author:
#   TAKAHASHI Kazunari[takahashi@1syo.net]
Deserializer = require 'xmlrpc/lib/deserializer'
Serializer = require 'xmlrpc/lib/serializer'
_ = require 'underscore'

class Postman
  constructor: (params, @robot) ->
    @struct = params[3]

  message: ->
    result = []
    result.push @struct.title if @struct.title
    result.push @struct.description if @struct.description
    result.join("\n")

  deliver: ->
    _.each @struct.categories, (category) =>
      @robot.send {room: category} , @message()

module.exports = (robot) ->
  robot.router.post "/#{robot.name}/xmlrpc.php", (req, res) ->

    success = (value) ->
      body = Serializer.serializeMethodResponse(value)

      header = {
        'Content-Type': 'text/xml',
        'Content-Length': body.length
      }

      res.writeHead 200, header
      res.end body

    failure = (value) ->
      data = {
        "faultCode": value,
        "faultString": "Request was not successful."
      }

      body = Serializer.serializeFault(data)

      header = {
        'Content-Type': 'text/xml',
        'Content-Length': body.length
      }

      res.writeHead 404, header
      res.end body

    deserializer = new Deserializer()
    deserializer.deserializeMethodCall req, (err, methodName, params) ->
      if err
        failure("404")
        return

      switch methodName
        when "mt.supportedMethods"
          success("metaWeblog.getRecentPosts")
        when "metaWeblog.getRecentPosts"
          success([])
        when "metaWeblog.newPost"
          postman = new Postman(params, robot)
          postman.deliver()
          success("200")
        else
          failure("404")
