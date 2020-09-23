```
nsupdate <<!
server enneesseuno.ethiclab.it 53
zone ethiclab.online
update add pippo.ethiclab.online 3600 TXT TEST
key test <PASSWORD>
send
!
```
