#!/bin/bash                                                                                                                                                                                                         
                                                                                                                                                                                                                    
echo "---------------------------------------------------------------------------------------------------------"                                                                                                    
echo "Login as Hunchentoot and start the Webpush Server"                                                                                                                                                            
echo "---------------------------------------------------------------------------------------------------------"                                                                                                    
cd /home/ubuntu/webpushserver                                                                                                                                                                                       
pm2 start index.js --name "Webpush Server"                                                                                                                                                                          
                                                                                                                                                                                                                    
echo "---------------------------------------------------------------------------------------------------------"                                                                                                    
echo "Start the SMS Server"                                                                                                                                                                                         
echo "---------------------------------------------------------------------------------------------------------"                                                                                                    
                                                                                                                                                                                                                    
cd /home/ubuntu/smsserver                                                                                                                                                                                           
pm2 start index.js --name "SMS Server"                                                                                                                                                                              
                                                                                                                                                                                                                    
echo "---------------------------------------------------------------------------------------------------------"                                                                                                    
echo "Start SBCL "                                                                                                                                                                                                  
echo "---------------------------------------------------------------------------------------------------------"                                                                                                    
                                                                                                                                                                                                                    
sudo /etc/init.d/hunchentoot stop                                                                                                                                                                                   
sudo /etc/init.d/hunchentoot clear                                                                                                                                                                                  
sudo /etc/init.d/hunchentoot start                                                                                                                                                                                  
                                              

