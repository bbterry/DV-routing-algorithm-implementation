'''
This Client is wirtten by Terry Lin
date:2013/09/28
school: The George Washington University
'''

from socket import *
import sys

clientsocket = socket(AF_INET, SOCK_STREAM)

if len(sys.argv) != 4:
    print len(sys.argv)
    print"Your command is not right. Please be in this format:client.py server_host server_port filename"
    sys.exit(0)

host = str(sys.argv[1])
port = int(sys.argv[2])
request = str(sys.argv[3])
request = "GET /" + request + " HTTP/1.1"
try:
    clientsocket.connect((host,port))
except Exception,data:
    print Exception,":",data
    print "Please try again.\r\n"
    sys.exit(0)
clientsocket.send(request)
    
response = clientsocket.recv(1024)
    
print response + "\r\n"
    
clientsocket.close()

host = ''

while True:

 clientsocket = socket(AF_INET, SOCK_STREAM)

 host = raw_input("Input Host Address:")

 port = int(raw_input("Input Port Number:"))

 request = raw_input("Input Requested Filename:")

 request = "GET /" + request + " HTTP/1.1"

 try:
  clientsocket.connect((host,port))

 except Exception,data:
  print Exception,":",data
  print "Please try again.\r\n"
  continue
        
 clientsocket.send(request)
    
 response = clientsocket.recv(1024)
    
 print response + "\r\n"
    
 clientsocket.close()

 
