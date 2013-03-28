###
#
# Description:
#   'If you have to do it more than 3 times, script it.'
#   We have to answer lots of the same questions from our boss in IRC.
#   Until now.
#
# Dependencies:
#   Our boss
#
# Author:
#   Zac Echola @zacechola
#   With respect to Dustin Rue for issuing this code challenge
###

module.exports = (robot) ->

  builds ?= {}

  # We'll be doing this often
  isWelle = (sender) ->
    if sender is "cwelle" or sender is "chriswelle"
      return true


  ###
  #
  # We have a process of not breaking anything on Fridays, because nobody likes
  # working over the weekend fixing horrible bugs. Still, cwelle asks for
  # launches at awful times sometimes. 
  #
  # This section reminds him of the time of the day/week, so we don't
  # have to do the reminding anymore.
  #
  ###

  # Don't Break Anything Friday Process
  robot.hear /push.*production|production.*push/i, (msg) ->
    sender = msg.message.user.name.toLowerCase()
    time = new Date().getHours()
    day = new Date().getDay()

    if isWelle(sender) is true
      if time > 16
        msg.send "It's after 4p.m."
      else if time > 16 and day is 5
        msg.send "Fuck it. Let's ship. What could go wrong?"
      else
        response = [
           'Who knows?',
           'Ask someone else',
           'Uh... probably?',
           'If that is what you want',
           'Is staging working now?',
           'If it makes you feel better...',
           'As you wish. Building now.... \n FAILURE in ' + Math.floor(Math.random() * 2) + 2 + '.' + Math.floor(Math.random() * 3) + 2 + ' seconds'
        ]
        msg.send msg.random response


  ###
  #
  # Page drue and zechola when the boss wants a staging push
  # He often asks, but neither of us are paying attention to the chatroom.
  # Sometimes hours go by and he'll ask more than once before we notice it.
  #
  # TODO:
  #   Make the robots checkout the code to the staging branch when asked?
  ###

  robot.hear /push.*staging|staging.*push/i, (msg) ->
    sender = msg.message.user.name.toLowerCase()
    if isWelle(sender) then msg.send "Paging drue, zechola."


  ###
  #
  # Something is building right now. It never fails that he notices something
  # is 'broken' in the middle of a build. The robots announce builds to the room
  # but it's like cwelle is impervious to noticing those announcements.
  #
  # This is a gentile reminder that yes, there are still builds running. They
  # take time to complete.
  #
  ###

  # Listen for build starts
  robot.hear /starting build (#(.*)) for job (.*) \(/i, (msg) ->
    sender = msg.message.user.name.toLowerCase()
    number = msg.match[2]
    name = msg.match[3] 

    # Create Build objects
    class Build
      constructor: (@number, @name) ->

      number: @number
      name: @name

    # Add this build to the global builds object
    tmp = new Build number, name
    builds[tmp.number] = tmp

  # Destroys builds when they end
  robot.hear /build (#(.*)): (SUCCESS|FAILURE|STILL FAILING|FIXED) in/i, (msg) ->
    number = msg.match[2]
    if builds[number]
      delete builds[number]


  # Listen for questions from cwelle while there are active builds and respond
  robot.hear /(.*\?)/i, (msg) ->
    sender = msg.message.user.name.toLowerCase()


    if isWelle(sender) is true and Object.keys(builds).length > 0

      # Let's try to guess what cwelle is talking about in the most rudimentary
      # way possible
      msg_test = switch
          when msg.indexOf('production') > -1 then 'production'
          when msg.indexOf('live') > -1 then 'production'
          when msg.indexOf('testing') > -1 then 'testing'
          when msg.indexOf('upgradetesting') > -1 then 'upgradetesting'
          when msg.indexOf('staging') > -1 then 'staging'
          else null

      # Snark!
      snark = [
        sender + ': I may be of some help to you.',
        'I am a robot that has been trained to read the logs for you, ' + sender,
        'I got this, ' + sender + '.',
        'Perhaps the answers to your questions may be related to the following.'
      ]
      # Send that snark!
      msg.send msg.random snark

      # Builds in progress messages
      still_building = (number, name) ->
        msg.send 'Still Building: ' + number + ' - ' + name


      # Loop through the active builds
      for k of builds
        name = builds[k].name
        number = builds[k].number

        # Find builds directly related to cwelle's question, else send all active
        switch
          when name.toLowerCase().indexOf(msg_test) > -1 then still_building(number, name)
          else still_building(number, name)

  ###
  #
  # This extra credit section will keep a record of all things cwelle says in 
  # chat. It will then learn from direct responses to him from devs in the 
  # chatroom. Over time, Hubot will begin responding to cwelle about common
  # things he brings up, using our past responses as its answers.
  #
  ###

  robot.hear /^(.*)/i, (msg) ->
    sender = msg.message.user.name.toLowerCase()

    robot.brain.data.chrisfaq ?= []

    # Did the boss just speak? What did he say?
    if isWelle(sender)
      cwelle_said is on
      said = msg.match[1]

    # Direct responses to cwelle immediately after he has spoken are recorded
    # We'll record this for data science until I come up with a good method
    # for selecting the best responses.
    if msg.indexOf('cwelle') or msg.indexOf('chriswelle') and cwelle_said is on
      cwelle_said is off
      response = msg.match[1]
      from = msg.message.user.name.toLowerCase()
      robot.brain.data.chrisfaq.push { said: said, response: response, from: from }
    else
      cwelle_said is off

