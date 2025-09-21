import os
from locust import HttpUser, task, between

# Read environment variables
TARGET_HOST = os.getenv("TARGET_HOST", "http://localhost:8080")
WAIT_TIME_MIN = int(os.getenv("WAIT_TIME_MIN", 1))
WAIT_TIME_MAX = int(os.getenv("WAIT_TIME_MAX", 5))
FRONTEND_PATH = os.getenv("FRONTEND_PATH", "/")
BACKEND_PATH = os.getenv("BACKEND_PATH", "/api/tasks")

class WebsiteUser(HttpUser):
    host = TARGET_HOST
    wait_time = between(WAIT_TIME_MIN, WAIT_TIME_MAX)

    @task(3)
    def hit_frontend(self):
        self.client.get(FRONTEND_PATH)

    @task(7)
    def hit_backend(self):
        # Example: backend endpoint to list tasks
        self.client.get(BACKEND_PATH)
