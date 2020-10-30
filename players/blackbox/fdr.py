import pcm825
import socket
import jsonpickle
import json
import logging
import logging.handlers
import time
import random
import codecs

lstnr = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
lstnr.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
lstnr.bind(("0.0.0.0", 34568))
stream = pcm825.KaitaiStream(lstnr.makefile('rb'))

def makeHandler(num):
    handler = logging.handlers.TimedRotatingFileHandler(
        'log/fdr-log-%s.log'%num, when='m', backupCount=1)
    logger = logging.getLogger('Flight Data Recorder %s'%num)
    logger.addHandler(handler)
    logger.setLevel(logging.INFO)
    return logger

loggers = [makeHandler(i) for i in range(20)]

while True:
    time.sleep(0.1)
    for logger in loggers:
        log = ''
        for i in range(100):
            packet = pcm825.Pcm825(stream)
            log += jsonpickle.encode(packet.pcm825, unpicklable=False)
        log = log.encode()
        logger.info(codecs.encode(codecs.encode(log, 'zlib'), 'base64'))
