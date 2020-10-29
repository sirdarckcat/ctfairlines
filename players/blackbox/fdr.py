import pcm825
import socket
import jsonpickle
import json
import logging
import logging.handlers

lstnr = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
lstnr.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
lstnr.bind(("0.0.0.0", 34568))
stream = pcm825.KaitaiStream(lstnr.makefile('rb'))
handler = logging.handlers.TimedRotatingFileHandler(
    'log/fdr-log', when='m', backupCount=3)
logger = logging.getLogger('Flight Data Recorder')
logger.addHandler(handler)
logger.setLevel(logging.INFO)

while True:
    packet = pcm825.Pcm825(stream)
    logger.info(jsonpickle.encode(packet.pcm825, unpicklable=False))
