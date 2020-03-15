#!/bin/bash                                                                                                                                                            
                                                                                                                                                                       
sudo ln -s /home/ubuntu /home/psergey                                                                                                                                  
                                                                                                                                                                       
cd /home/ubuntu                                                                                                                                                        
git clone https://github.com/urcu/userspace-rcu.git                                                                                                                    
cd userspace-rcu                                                                                                                                                       
sudo apt-get install automake                                                                                                                                          
./bootstrap                                                                                                                                                            
./configure --prefix=/home/ubuntu/userspace-rcu-dist                                                                                                                   
make -j10                                                                                                                                                              
make install                                                                                                                                                           

