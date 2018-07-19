import logging

LOG_FILE = "mcycle.log"
LOG_FILEMODE = "w"
LOG_LEVEL = "DEBUG"
LOGGER = logging.getLogger()


def updateLogger():
    logLevel = getattr(logging, LOG_LEVEL, None)
    if not isinstance(logLevel, int):
        raise ValueError('Invalid log level: %s' % LOG_LEVEL)
    #LOGGER = logging.getLogger()
    LOGGER.setLevel(logLevel)
    fh = logging.FileHandler(LOG_FILE, LOG_FILEMODE, delay=True)
    fh.setLevel(logLevel)
    formatter = logging.Formatter(
        '%(asctime)s - %(levelname)s: %(message)s [%(exc_text)s]',
        datefmt='%Y/%m/%d %I:%M:%S%p')
    fh.setFormatter(formatter)
    LOGGER.addHandler(fh)


updateLogger()


def log(lvl, msg, *args, **kwargs):
    assert lvl.lower() in [
        "notset", "debug", "info", "warning", "error", "critical"
    ], "{} is not a valid logging level".format(lvl)
    lvls = {
        "notset": logging.NOTSET,
        "debug": logging.DEBUG,
        "info": logging.INFO,
        "warning": logging.WARN,
        "error": logging.ERROR,
        "critical": logging.CRITICAL
    }
    LOGGER.log(lvls[lvl.lower()], msg, *args, **kwargs)
