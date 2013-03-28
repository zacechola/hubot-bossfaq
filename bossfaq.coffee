# Description:
#   'If you have to do it more than 3 times, script it.'
#   We have to answer lots of the same questions from our boss in IRC.
#   Until now.
#
# Dependencies:
#   Our specific jenkins-bot set up for IRC
#   Our boss
#
# Configuration:
#  HUBOT_BOSSFAQ_BOSS
#
# Author:
#   Zac Echola @zacechola
#   With respect to Dustin Rue for issuing this code challenge

module.exports = (robot) ->

  builds = {}
  boss = process.env.HUBOT_BOSSFAQ_BOSS

  # We'll be doing this often
  isBoss = (sender) ->
    if sender is boss
      return true


  ###
  #
  # We have a process of not breaking anything on Fridays, because nobody likes
  # working over the weekend fixing horrible bugs. Still, the boss asks for
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

    if isBoss(sender) is true
      if time > 16 and day is 5
        msg.send "Fuck it. Let's ship. What could go wrong?"
      else if time > 16
        msg.send "It's after 4p.m."
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
  # Page drue and zechola when the the boss wants a staging push
  # He often asks, but neither of us are paying attention to the chatroom.
  # Sometimes hours go by and he'll ask more than once before we notice it.
  #
  # TODO:
  #   Make the robots checkout the code to the staging branch when asked?
  #   Allow for configuration of who to page
  ###

  robot.hear /push.*staging|staging.*push/i, (msg) ->
    sender = msg.message.user.name.toLowerCase()
    if isBoss(sender) then msg.send "Paging drue, zechola."


  ###
  #
  # Something is building right now. It never fails that he notices something
  # is 'broken' in the middle of a build. The robots announce builds to the room
  # but it's like the boss is impervious to noticing those announcements.
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

  # Destroys builds when they end and logs recent failures
  # TODO:
  #   Log recent failures and aborts, as those explain why things are actually
  #   broken rather than temporarily broken
  robot.hear /build (#(.*)): (SUCCESS|FAILURE|STILL FAILING|FIXED|ABORTED) in/i, (msg) ->
    number = msg.match[2]
    if builds[number]
      delete builds[number]


  # Listen for questions from the boss while there are active builds and respond
  robot.hear /(.*\?)/i, (msg) ->
    sender = msg.message.user.name.toLowerCase()


    if isBoss(sender) is true and Object.keys(builds).length > 0

      # Let's try to guess what the boss is talking about in the most rudimentary
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

        # Find builds directly related to the boss's question, else send all active
        switch
          when name.toLowerCase().indexOf(msg_test) > -1 then still_building(number, name)
          else still_building(number, name)

  ###
  #
  # This extra credit section will keep a record of all things the boss says in 
  # chat. It will then learn from direct responses to him from devs in the 
  # chatroom. Over time, Hubot will begin responding to the boss about common
  # things he brings up, using our past responses as its answers.
  #
  # TODO:
  #   Once we've recorded phrases from the boss and our responses, we'll need to
  #   figure out how we can get the robot to respond to common questions with
  #   seemingly appropriate statements from the developers.
  #
  ###

  robot.hear /^(.*)/i, (msg) ->
    sender = msg.message.user.name.toLowerCase()

    robot.brain.data.bossfaq ?= []

    # Did the boss just speak? What did he say?
    if isBoss(sender)
      boss_said is on
      said = msg.match[1]

    # Direct responses to the boss immediately after he has spoken are recorded
    # We'll record this for data science until I come up with a good method
    # for selecting the best responses.
    if msg.indexOf(boss) and boss_said is on
      boss_said is off
      response = msg.match[1]
      from = msg.message.user.name.toLowerCase()
      robot.brain.data.bossfaq.push { said: said, response: response }
    else
      boss_said is off
