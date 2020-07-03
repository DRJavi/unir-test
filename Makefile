.PHONY: all $(MAKECMDGOALS)

build:
	docker build -t calculator-app .

run:
	docker run --rm --volume `pwd`:/opt/calc --env PYTHONPATH=/opt/calc -w /opt/calc calculator-app:latest python -B app/calc.py

server:
	docker run --rm --volume `pwd`:/opt/calc --name apiserver --network-alias apiserver --env PYTHONPATH=/opt/calc --env FLASK_APP=app/api.py -p 5000:5000 -w /opt/calc calculator-app:latest flask run --host=0.0.0.0

test-unit:
	docker run --rm --volume `pwd`:/opt/calc --env PYTHONPATH=/opt/calc -w /opt/calc calculator-app:latest pytest --cov --cov-report=xml:results/cov_result.xml --cov-report=html:results/cov_result --junit-xml=results/unit_result.xml -m unit || true
	docker run --rm --volume `pwd`:/opt/calc --env PYTHONPATH=/opt/calc -w /opt/calc calculator-app:latest junit2html results/unit_result.xml results/unit_result.html

test-api:
	docker network create calc
	docker run -d --rm --volume `pwd`:/opt/calc --network calc --env PYTHONPATH=/opt/calc --name apiserver --env FLASK_APP=app/api.py -p 5000:5000 -w /opt/calc calculator-app:latest flask run --host=0.0.0.0
	docker run --rm --volume `pwd`:/opt/calc --network calc --env PYTHONPATH=/opt/calc --env BASE_URL=http://apiserver:5000/ -w /opt/calc calculator-app:latest pytest --junit-xml=results/api_result.xml -m api  || true
	docker run --rm --volume `pwd`:/opt/calc --env PYTHONPATH=/opt/calc -w /opt/calc calculator-app:latest junit2html results/api_result.xml results/api_result.html
	docker rm --force apiserver
	docker network rm calc

interactive:
	docker run -ti --rm --volume `pwd`:/opt/calc --env PYTHONPATH=/opt/calc  -w /opt/calc calculator-app:latest bash

test-cypress:
	docker network create calc
	docker run -d --rm --volume `pwd`:/opt/calc --network calc --env PYTHONPATH=/opt/calc --name apiserver --env FLASK_APP=app/api.py -p 5000:5000 -w /opt/calc calculator-app:latest flask run --host=0.0.0.0
	docker run -d --rm --volume `pwd`/web:/usr/share/nginx/html --network calc --name calc-web -p 80:80 nginx
	docker run --rm --volume `pwd`/test/e2e/cypress.json:/cypress.json --volume `pwd`/test/e2e/cypress:/cypress --volume `pwd`/results:/results  --network calc cypress/included:4.9.0 --browser chrome || true
	docker rm --force apiserver
	docker rm --force calc-web
	docker run --rm --volume `pwd`:/opt/calc --env PYTHONPATH=/opt/calc -w /opt/calc calculator-app:latest junit2html results/cypress_result.xml results/cypress_result.html
	docker network rm calc

run-web:
	docker run --rm --volume `pwd`/web:/usr/share/nginx/html --name calc-web -p 80:80 nginx

stop-web:
	docker stop calc-web