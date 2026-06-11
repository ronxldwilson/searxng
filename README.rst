searxng-slim
============

.. image:: https://img.shields.io/docker/pulls/ronxldwilson/searxng-slim.svg
   :target: https://hub.docker.com/r/ronxldwilson/searxng-slim/

.. image:: https://img.shields.io/docker/image-size/ronxldwilson/searxng-slim?sort=semver
   :target: https://hub.docker.com/r/ronxldwilson/searxng-slim/

A stripped-down SearXNG image optimized for **JSON-only, API-driven search** — no UI, no static assets, minimal dependencies. Built for programmatic web scraping and data harvesting pipelines.

Recommended to use with `torousel <https://github.com/ronxldwilson/torousel>`_ (``ronxldwilson/torousel``) as the Tor proxy for anonymous, IP-rotating search.

What's included
---------------

- All search engines (Google, Bing, DuckDuckGo, Brave, Yandex, Yahoo, Mojeek, Qwant, Presearch, and more)
- JSON and CSV output formats
- Full plugin system (calculator, hash, unit converter, etc.)
- jemalloc allocator for lower memory usage
- Multi-arch: ``linux/amd64``, ``linux/arm64``

What's stripped
---------------

- HTML templates and static assets (CSS, JS, images)
- Unused Python packages (pygments, markdown-it-py, h2, hpack, hyperframe)
- No web UI — API-only

Quick start
-----------

.. code-block:: yaml

   # docker-compose.yml
   services:
     torousel:
       image: ronxldwilson/torousel:latest

     searxng:
       image: ronxldwilson/searxng-slim:latest
       ports:
         - "8888:8080"
       volumes:
         - ./settings.yml:/etc/searxng/settings.yml:ro
       depends_on:
         - torousel

.. code-block:: yaml

   # settings.yml
   use_default_settings: true

   server:
     secret_key: "change-me"
     bind_address: "0.0.0.0"
     port: 8080
     limiter: false

   outgoing:
     proxies:
       all://:
         - http://torousel:3128

Query the API:

.. code-block:: bash

   curl -s "http://localhost:8888/search?q=test&format=json" | python3 -m json.tool

Platforms
---------

- ``linux/amd64``
- ``linux/arm64``

Based on
--------

- `SearXNG <https://github.com/searxng/searxng>`_ (AGPL-3.0)
- `torousel <https://github.com/ronxldwilson/torousel>`_ (recommended proxy)

License
-------

AGPL-3.0 (same as upstream SearXNG)
