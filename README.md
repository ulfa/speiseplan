Wie teste ich mit curl:

curl -X POST -u user:password  -H "Content-Type: application/x-www-form-urlencoded" "http://localhost:8090/kiezkantine/apns/register" -d "device_token=1234token"