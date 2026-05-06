FROM debian:bookworm-slim AS jemalloc-builder
RUN apt-get update && apt-get install -y --no-install-recommends build-essential wget bzip2 ca-certificates && \
    cd /tmp && \
    wget -q https://github.com/jemalloc/jemalloc/releases/download/5.3.0/jemalloc-5.3.0.tar.bz2 && \
    tar xjf jemalloc-5.3.0.tar.bz2 && \
    cd jemalloc-5.3.0 && \
    ./configure --prefix=/usr/local && \
    make -j$(nproc) && \
    make install

FROM searxng/searxng:latest
USER root

COPY --from=jemalloc-builder /usr/local/lib/libjemalloc.so.2 /usr/local/lib/libjemalloc.so.2

# Overlay stripped source (engines, data, static, translations, webapp.py)
COPY --chown=977:977 ./searx/ /usr/local/searxng/searx/

# Strip unused: packages, templates, static assets
RUN .venv/bin/pip uninstall -y pygments markdown-it-py h2 hpack hyperframe 2>/dev/null; \
    find /usr/local/searxng/searx/static/ -type f -delete 2>/dev/null; \
    find /usr/local/searxng/searx/templates/ -name "*.html" -not -name "opensearch.xml" -delete 2>/dev/null; \
    find /usr/local/searxng/ -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null; \
    .venv/bin/python -m compileall -q searx/ 2>/dev/null; true

ENV GRANIAN_BLOCKING_THREADS="1" \
    LD_PRELOAD="/usr/local/lib/libjemalloc.so.2" \
    PYTHONMALLOC="malloc" \
    MALLOC_CONF="dirty_decay_ms:1000,muzzy_decay_ms:1000"

USER searxng
