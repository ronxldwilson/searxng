FROM searxng/searxng:latest

USER root

# Overlay stripped source (engines, data, static, translations, webapp.py)
COPY --chown=977:977 ./searx/ /usr/local/searxng/searx/

# Remove packages no longer imported (pygments, markdown-it-py, h2/hpack/hyperframe for http2)
RUN .venv/bin/pip uninstall -y pygments markdown-it-py h2 hpack hyperframe 2>/dev/null; \
    find .venv/lib/ -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null; true

ENV GRANIAN_BLOCKING_THREADS="1" \
    MALLOC_ARENA_MAX="2"

USER searxng
