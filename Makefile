bot_bash:
	docker run -it -v /Users/leenday/Documents/Programming/telegram_bots/asit:/bot bot bash

run_bot:
	bundle exec ruby ./app/main.rb

rm_none_images:
	docker images | grep '^<none>' | tr -s ' ' | cut -d ' ' -f 3 | xargs docker rmi

