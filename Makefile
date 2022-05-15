run_bot:
	bundle exec ruby ./app/main.rb

rm_none_images:
	docker images | grep '^<none>' | tr -s ' ' | cut -d ' ' -f 3 | xargs docker rmi

db_setup:
	docker-compose run --rm bot bash -c "rake db:create db:migrate"
