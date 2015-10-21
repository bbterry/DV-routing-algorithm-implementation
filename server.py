'''
This HttpServer is wirtten by Terry Lin
date:2013/09/28
school: The George Washington University
'''

from socket import *
import sys, os, time, thread

count = 0

#Define a function for the thread
def run_server(threadName,delay):

    global count

    while 1:

      connectionsocket, addr = serversocket.accept()

     #print "connected from:",addr

     #try:
         
      request = connectionsocket.recv(1024)

      #print request

      if request == '':
          continue

      method = request.split(' ')[0]

      print "Request Method: " + method
      count = count + 1
      print "Connections have been established:", count
      print "\r\n"
      
      request = request.split('\r\n')

      if '/ ' in request[0]:
          f = open('index.htm')
          content = f.read()
          f.close()

      else:
          request_file = request[0].split(' ')[1][1:]

          exist_flag = os.path.exists(request_file)

          if exist_flag == True:
              f = open(request_file,'rb')
              content = f.read()
              f.close()

          else:
              connectionsocket.send('<h1>404 Not Found</h1>')
              continue

      response_data = "HTTP/1.1 200 OK\r\n" +  \
                                        "Server: HTTP Server BY Terry Lin\r\n" +  \
                                        "Date: %s \r\n" %  time.strftime('%Y-%m-%d', time.localtime(time.time() ) )  +  \
                                        "Content-Type: text/html;charset=utf-8\r\n\r\n" +  \
                                        content     

      connectionsocket.send(response_data)
      


      connectionsocket.close()

      time.sleep(delay)

     #except IOError:
         
      #connectionsocket.send("HTTP/1.1 404 Not Found\r\n\r\n")

      #connectionsocket.close()

#Create two threads as follows
try:
    
    serverport = 55666

    serversocket = socket(AF_INET, SOCK_STREAM)

    serversocket.bind(('', serverport))

    serversocket.listen(1)

    print"Ready to serve..."
    
    thread.start_new_thread(run_server,("Thread-1",0.3,))
    thread.start_new_thread(run_server,("Thread-2",0.6,))
    #thread.start_new_thread(run_server,("Thread-3",0.9,))
    
except:
    print"Error:unable to start thread"
    while 1:
        pass
    


