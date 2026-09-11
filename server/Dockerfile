FROM python:3.12-slim
WORKDIR /app
COPY feedback_server.py storage.py community.py community_rules.json ./
USER 65532:65532
ENV PYTHONDONTWRITEBYTECODE=1 VNB_BIND=0.0.0.0 VNB_DATABASE=/data/feedback.sqlite
EXPOSE 8765
HEALTHCHECK --interval=30s --timeout=5s CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8765/v1/health',timeout=3)"
CMD ["python", "feedback_server.py"]
