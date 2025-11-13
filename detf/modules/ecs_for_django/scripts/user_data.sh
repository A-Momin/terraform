cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
    "metrics": {
        "namespace": "ECS/Django",
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    "cpu_usage_idle",
                    "cpu_usage_iowait",
                    "cpu_usage_user",
                    "cpu_usage_system"
                ],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": [
                    "used_percent"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "diskio": {
                "measurement": [
                    "io_time"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 60
            }
        }
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/ecs/ecs-agent.log",
                        "log_group_name": "/aws/ecs/agent",
                        "log_stream_name": "{instance_id}"
                    },
                    {
                        "file_path": "/var/log/ecs/ecs-init.log",
                        "log_group_name": "/aws/ecs/init",
                        "log_stream_name": "{instance_id}"
                    }
                ]
            }
        }
    }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
    -s

# Install additional monitoring tools
yum install -y htop

# Set up log rotation
cat > /etc/logrotate.d/ecs << 'EOF'
/var/log/ecs/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    copytruncate
}
EOF

# Create health check script
cat > /usr/local/bin/ecs-health-check.sh << 'EOF'
#!/bin/bash
# ECS Health Check Script

# Check if ECS agent is running
if ! pgrep -f ecs-agent > /dev/null; then
    echo "ECS agent is not running"
    exit 1
fi

# Check if Docker is running
if ! systemctl is-active --quiet docker; then
    echo "Docker is not running"
    exit 1
fi

# Check disk space
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 90 ]; then
    echo "Disk usage is above 90%"
    exit 1
fi

echo "Health check passed"
exit 0
EOF

chmod +x /usr/local/bin/ecs-health-check.sh

# Set up cron job for health checks
echo "*/5 * * * * /usr/local/bin/ecs-health-check.sh >> /var/log/health-check.log 2>&1" | crontab -

# Configure Docker daemon for better performance
cat > /etc/docker/daemon.json << 'EOF'
{
    "log-driver": "awslogs",
    "log-opts": {
        "awslogs-group": "/aws/ecs/containerinsights",
        "awslogs-region": "us-east-1"
    },
    "storage-driver": "overlay2",
    "max-concurrent-downloads": 10,
    "max-concurrent-uploads": 5
}
EOF

# Restart Docker to apply configuration
service docker restart

# Wait for ECS agent to register
sleep 30

echo "ECS instance setup completed successfully"