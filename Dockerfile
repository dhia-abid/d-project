# Use Python 3.11 slim image as base
# This is a lightweight Python image with minimal dependencies
FROM python:3.11-slim

# Set the working directory inside the container
# All subsequent commands will run from this directory
WORKDIR /app

# Set environment variables
# PYTHONDONTWRITEBYTECODE: Prevents Python from writing .pyc files
# PYTHONUNBUFFERED: Ensures Python output is sent straight to stdout/stderr
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Copy requirements file first
# This is done before copying the rest of the code to leverage Docker cache
# If requirements.txt doesn't change, Docker uses cached layer
COPY app/requirements.txt .

# Install Python dependencies
# --no-cache-dir: Reduces image size by not caching downloaded packages
RUN pip install --no-cache-dir -r requirements.txt

# Copy the entire application directory
# This includes app.py, templates, and static files
COPY app/ .

# Expose port 5000
# This is documentation only - actual port mapping happens at runtime
# It tells users which port the application listens on
EXPOSE 5000

# Command to run the application
# Using gunicorn as a production WSGI server instead of Flask's built-in server
# --bind 0.0.0.0:5000: Listen on all interfaces, port 5000
# --workers 4: Use 4 worker processes for better performance
# app:app: The WSGI application (module:variable)
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "4", "app:app"]
