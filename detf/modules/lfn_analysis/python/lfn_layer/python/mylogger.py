import decimal
import logging
import os
import json
from datetime import datetime
from typing import Optional, Union
import coloredlogs
from termcolor import colored
from pathlib import Path
BASE_DIR = Path(__file__).resolve().parent.parent


class JsonHelper(json.JSONEncoder):
    """Helper class to convert non-serializable objects to JSON serializable types."""
    def default(self, obj):
        if isinstance(obj, decimal.Decimal):
            return int(obj)
        if isinstance(obj, datetime):
            return str(obj)
        if isinstance(obj, set):
            return list(obj)
        if isinstance(obj, bytes):
            return obj.decode('utf-8', errors='ignore')
        if not isinstance(obj, (str, int, float, bool, list, dict)):
            return str(obj)
        return super(JsonHelper, self).default(obj)
        # return super().default(obj)

class CustomLogger:

    log_level = logging.INFO
    local = True
    propagate = False

    def __init__(self, logger=None, log_dir: Optional[str] = None):
        self.log_dir = log_dir
        self.logger = logger or initialize_logger(__name__)

    def log(self):
        if self.logger: return self.logger
        return initialize_logger(__name__, logfile={"dir":self.log_dir})

    def get_message(self, message, details: Optional[Union[str, dict]] = None, color: Optional[str] = None):
        try:
            if isinstance(message, (list, dict)):
                message = json.dumps(message, indent=4 if self.local else None, cls=JsonHelper)
            if details:
                if message[-1] != ":":
                    message += ":"
                if isinstance(details, (list, dict)):
                    details = json.dumps(details, indent=4 if self.local else None, cls=JsonHelper)
                message += f"\n{details}"
            return colored(message, color) if color else message
        except Exception:
            return message

    def info(self, message, details: Optional[Union[str, dict]] = None, color: Optional[str] = None):
        self.log().info(self.get_message(message, details, color), stacklevel=5)

    def debug(self, message, details: Optional[Union[str, dict]] = None, color: Optional[str] = None):
        self.log().debug(self.get_message(message, details, color), stacklevel=5)

    def warning(self, message, details: Optional[Union[str, dict]] = None, color: Optional[str] = None):
        self.log().warning(self.get_message(message, details, color), stacklevel=5)

    def error(self, message, details: Optional[Union[str, dict]] = None, color: Optional[str] = None):
        self.log().error(self.get_message(message, details, color), stacklevel=5)

    def full_output(self, values: dict) -> None:
        with open("output.json", "w", encoding="utf-8") as output_file:
            json.dump(values, output_file, indent=4)

def initialize_logger(logger_name, logfile={"dir": BASE_DIR, "Name":"", "mode":""}):

    log_format = "%(levelname)s: %(asctime)s [%(filename)s:%(lineno)d] %(message)s"
    log_date_format = "%Y-%m-%d %H:%M:%S"
    log_level = os.getenv("LOG_LEVEL", "INFO").upper()

    logger = logging.getLogger(logger_name)
    logger.setLevel(log_level)
    logger.propagate = False
    # logger.handlers = []  # Clear existing handlers

    coloredlogs.DEFAULT_FIELD_STYLES.update(dict(
        asctime=dict(bold=True, color='white'),
        levelname=dict(bold=True, color='green'),
        filename=dict(bold=True, color='magenta'),
        lineno=dict(bold=True, color='cyan')
    ))

    coloredlogs.DEFAULT_LEVEL_STYLES.update(dict(
        critical=dict(bold=True, color='red'),
        error=dict(bold=True, color='red'),
        warning=dict(bold=True, color='yellow'),
        info=dict(bold=True, color='green'),
        debug=dict(bold=True, color='blue')
    ))

    coloredlogs.install(
        level=log_level,
        fmt=log_format,
        datefmt=log_date_format,
        logger=logger
    )

    if logfile:
        os.makedirs(logfile.get("dir", BASE_DIR / "logs"), exist_ok=True)
        timestamp = datetime.now().strftime("%m-%d-%Y-%H%M%S")
        log_file = os.path.join(logfile['dir'], f"{logfile.get('name', logger_name) or logger_name}_{timestamp}.log")

        # Manually add a FileHandler for file output
        file_handler = logging.FileHandler(log_file, mode=logfile.get('mode', 'w') or 'w')  # Use 'a' to append or 'w' to overwrite
        file_handler.setLevel(logging.DEBUG)

        # # Optional: Add formatter for the file output
        # formatter = logging.Formatter("%(asctime)s - %(levelname)s - %(message)s")
        # file_handler.setFormatter(formatter)

        # Attach the file handler to the logger
        logger.addHandler(file_handler)

    return logger