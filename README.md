# Hubot BossFAQ

As with many of my scripts, this serves a pretty specific need. Our boss
tends to ask the same or extremely similar questions in IRC quite often.

This script saves us the hassle of repeating ourselves often. Ideally,
we'll start training the robot to learn common questions and responses
and eventually we'll all sign into the IRC chatroom as Hubots under our own
usernames.

The configuration is rather simple if you're familiar with deploying
Hubot. We simply need to set an environment variable for our boss's
username.

## For heroku

  heroku config:add HUBOT_BOSSFAQ_BOSS='username'

## For linux

  export HUBOT_BOSSFAQ_BOSS='username'
