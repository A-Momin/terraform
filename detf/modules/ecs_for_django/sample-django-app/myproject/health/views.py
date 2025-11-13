# Health Check Views for Django ECS Application

import json
import time
from django.http import JsonResponse
from django.db import connection
from django.core.cache import cache
from django.conf import settings
from django.views.decorators.http import require_http_methods
from django.views.decorators.csrf import csrf_exempt


@csrf_exempt
@require_http_methods(["GET"])
def health_check(request):
    """
    Comprehensive health check endpoint for load balancer
    Returns 200 if all systems are healthy, 503 if any critical system is down
    """
    start_time = time.time()

    health_status = {
        "status": "healthy",
        "timestamp": time.time(),
        "environment": getattr(settings, "ENVIRONMENT", "unknown"),
        "version": getattr(settings, "VERSION", "unknown"),
        "checks": {},
    }

    # Check database connectivity
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            cursor.fetchone()
        health_status["checks"]["database"] = {
            "status": "ok",
            "message": "Database connection successful",
        }
    except Exception as e:
        health_status["checks"]["database"] = {
            "status": "error",
            "message": f"Database connection failed: {str(e)}",
        }
        health_status["status"] = "unhealthy"

    # Check cache connectivity
    try:
        test_key = "health_check_test"
        test_value = f"test_{int(time.time())}"

        # Test write
        cache.set(test_key, test_value, 30)

        # Test read
        cached_value = cache.get(test_key)

        if cached_value == test_value:
            health_status["checks"]["cache"] = {
                "status": "ok",
                "message": "Cache read/write successful",
            }
            # Clean up test key
            cache.delete(test_key)
        else:
            health_status["checks"]["cache"] = {
                "status": "error",
                "message": "Cache read/write failed",
            }
    except Exception as e:
        health_status["checks"]["cache"] = {
            "status": "error",
            "message": f"Cache connection failed: {str(e)}",
        }
        # Cache failure is not critical, don't mark as unhealthy

    # Check disk space (if applicable)
    try:
        import shutil

        disk_usage = shutil.disk_usage("/")
        free_space_percent = (disk_usage.free / disk_usage.total) * 100

        if free_space_percent > 10:  # More than 10% free space
            health_status["checks"]["disk"] = {
                "status": "ok",
                "message": f"Disk space: {free_space_percent:.1f}% free",
                "free_space_percent": round(free_space_percent, 1),
            }
        else:
            health_status["checks"]["disk"] = {
                "status": "warning",
                "message": f"Low disk space: {free_space_percent:.1f}% free",
                "free_space_percent": round(free_space_percent, 1),
            }
    except Exception as e:
        health_status["checks"]["disk"] = {
            "status": "error",
            "message": f"Disk check failed: {str(e)}",
        }

    # Add response time
    health_status["response_time_ms"] = round((time.time() - start_time) * 1000, 2)

    # Determine HTTP status code
    status_code = 200 if health_status["status"] == "healthy" else 503

    return JsonResponse(health_status, status=status_code)


@csrf_exempt
@require_http_methods(["GET"])
def readiness_check(request):
    """
    Readiness check - determines if the application is ready to serve traffic
    This is used by Kubernetes/ECS for readiness probes
    """
    try:
        # Check if Django is properly initialized
        from django.apps import apps

        if not apps.ready:
            return JsonResponse(
                {"status": "not_ready", "message": "Django apps not ready"}, status=503
            )

        # Check database connectivity
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")

        return JsonResponse(
            {"status": "ready", "message": "Application is ready to serve traffic"},
            status=200,
        )

    except Exception as e:
        return JsonResponse(
            {"status": "not_ready", "message": f"Application not ready: {str(e)}"},
            status=503,
        )


@csrf_exempt
@require_http_methods(["GET"])
def liveness_check(request):
    """
    Liveness check - determines if the application is alive
    This is used by Kubernetes/ECS for liveness probes
    """
    return JsonResponse(
        {
            "status": "alive",
            "message": "Application is alive",
            "timestamp": time.time(),
        },
        status=200,
    )


@csrf_exempt
@require_http_methods(["GET"])
def version_info(request):
    """
    Version information endpoint
    """
    return JsonResponse(
        {
            "version": getattr(settings, "VERSION", "unknown"),
            "environment": getattr(settings, "ENVIRONMENT", "unknown"),
            "django_version": getattr(settings, "DJANGO_VERSION", "unknown"),
            "debug": settings.DEBUG,
            "timestamp": time.time(),
        },
        status=200,
    )
