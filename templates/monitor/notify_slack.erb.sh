#!/bin/bash

# This script is used by Nagios to post alerts into a Slack channel
# using the Incoming WebHooks integration. Create the channel, botname
# and integration first and then add this notification script in your
# Nagios configuration.
#
# More info on Slack
# Website: https://slack.com/
# Twitter: @slackhq, @slackapi
#
# My info
# Website: http://matthewcmcmillan.blogspot.com/
# Twitter: @matthewmcmillan

#Modify these variables for your environment
MY_NAEMON_HOSTNAME="monitor.drive.sunet.se"
SLACK_URL="<%= @slack_url %>"

#Set the message icon based on Nagios service state
if [ "$SERVICESTATE" = "CRITICAL" ]; then
	ICON=":exclamation:"
elif [ "$SERVICESTATE" = "WARNING" ]; then
	ICON=":warning:"
elif [ "$SERVICESTATE" = "OK" ]; then
	ICON=":white_check_mark:"
elif [ "$SERVICESTATE" = "UNKNOWN" ]; then
	ICON=":question:"
else
	ICON=":white_medium_square:"
fi

#Send message to Slack
payload='{"text": "'${ICON}' HOST: '${HOSTNAME}', SERVICE: '${SERVICEDISPLAYNAME}', MESSAGE: '${SERVICEOUTPUT}', (<https://'${MY_NAEMON_HOSTNAME}'/thruk/#cgi-bin/status.cgi?host='${HOSTNAME}'&style=detail|monitor.drive.sunet.se>)"}'
curl -X POST --data "${payload}" "${SLACK_URL}"
