searxng-slim
============

.. image:: https://img.shields.io/docker/pulls/ronxldwilson/searxng-slim.svg
   :target: https://hub.docker.com/r/ronxldwilson/searxng-slim/

.. image:: https://img.shields.io/docker/image-size/ronxldwilson/searxng-slim?sort=semver
   :target: https://hub.docker.com/r/ronxldwilson/searxng-slim/

A stripped-down SearXNG image optimized for **JSON-only, API-driven search** — no UI, no static assets, minimal dependencies. Runs **5 Granian workers by default**, replacing 5 separate SearXNG containers with a single one. Built for programmatic web scraping and data harvesting pipelines.

Recommended to use with `torousel <https://github.com/ronxldwilson/torousel>`_ (``ronxldwilson/torousel``) as the Tor proxy for anonymous, IP-rotating search.

5-in-1: Multi-worker architecture
----------------------------------

The image runs **5 Granian WSGI workers** (``GRANIAN_WORKERS=5``) inside a single container. Each worker is an independent process that can handle search requests concurrently. This means one ``searxng-slim`` container replaces 5 standard ``searxng/searxng`` containers for parallel workloads.

**How it works:**

- `Granian <https://github.com/emmett-framework/granian>`_ is SearXNG's WSGI server (replaces gunicorn/uwsgi)
- Each worker forks the SearXNG app into a separate process with its own PID
- Incoming requests are distributed across workers by the Granian master process
- All workers share the same Tor proxy (torousel), settings, and engine config

**Resource usage (5 workers):**

.. list-table::
   :header-rows: 1

   * - Metric
     - Value
   * - RAM (idle)
     - ~500 MiB
   * - PIDs
     - ~41
   * - Concurrent capacity
     - 5 parallel search requests

Override the worker count via environment variable:

.. code-block:: yaml

   environment:
     - GRANIAN_WORKERS=3    # fewer workers = less RAM

What's included
---------------

- All search engines (Google, Bing, DuckDuckGo, Brave, Yandex, Yahoo, Mojeek, Qwant, Presearch, and more)
- JSON and CSV output formats
- Full plugin system (calculator, hash, unit converter, etc.)
- jemalloc allocator for lower memory fragmentation
- Multi-arch: ``linux/amd64``, ``linux/arm64``

What's stripped
---------------

- HTML templates and static assets (CSS, JS, images)
- Unused Python packages (pygments, markdown-it-py, h2, hpack, hyperframe)
- No web UI — API-only

Implementation details
----------------------

The Dockerfile uses a multi-stage build:

1. **Stage 1 (jemalloc-builder):** Compiles jemalloc 5.3.0 from source on ``debian:bookworm-slim``
2. **Stage 2 (runtime):** Extends ``searxng/searxng:latest``, overlays stripped source, configures memory and workers

Key environment variables set in the image:

.. list-table::
   :header-rows: 1

   * - Variable
     - Value
     - Purpose
   * - ``GRANIAN_WORKERS``
     - 5
     - 5 concurrent WSGI worker processes
   * - ``GRANIAN_BLOCKING_THREADS``
     - 1
     - 1 blocking thread per worker (engine HTTP calls)
   * - ``LD_PRELOAD``
     - libjemalloc.so.2
     - Replace glibc malloc with jemalloc
   * - ``PYTHONMALLOC``
     - malloc
     - Bypass CPython's pymalloc arena allocator
   * - ``MALLOC_CONF``
     - dirty_decay_ms:1000,muzzy_decay_ms:1000
     - Aggressive jemalloc page return to OS

**Why jemalloc?** CPython's pymalloc + glibc malloc fragment heavily under SearXNG's allocation pattern (many short-lived HTTP response buffers). jemalloc with ``LD_PRELOAD`` + ``PYTHONMALLOC=malloc`` bypasses pymalloc entirely, reducing RSS by ~15% and preventing unbounded growth over long runs.

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
- `torousel <https://github.com/ronxldwilson/torousel>`_ (recommended Tor proxy)

License
-------

AGPL-3.0 (same as upstream SearXNG)
